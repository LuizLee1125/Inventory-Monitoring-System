// Landing screen: receivables, sales, stock health, recent activity.

import { api } from '../api.js';
import {
  card, clear, count, date, dataTable, el, money, stat, statusTag,
} from '../ui.js';
import { page, setTitle } from '../app.js';
import { onChange } from '../live.js';

// Same reasoning as the home screen: this is a monitor-in-the-corner screen, so
// the figures must not stop at whenever it was opened — and it is nobody's
// working screen, so a long debounce costs nothing and saves a redraw per
// invoice through a busy afternoon.
const REFRESH_MS = 3000;

let watching = null;

/** The router calls this when the screen is replaced. */
export function leave() {
  watching?.();
  watching = null;
}

const SVG_NS = 'http://www.w3.org/2000/svg';

/** `<rect>`, `<text>` and friends, with attributes. */
function svgEl(tag, attrs = {}, text = null) {
  const node = document.createElementNS(SVG_NS, tag);
  for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, value);
  if (text !== null) node.textContent = text;
  return node;
}

/** Axis labels: 1.2M and 450k rather than 1,240,000.00. */
function shortMoney(value) {
  const n = Math.abs(value);
  if (n >= 1_000_000) return `${(value / 1_000_000).toFixed(n >= 10_000_000 ? 0 : 1)}M`;
  if (n >= 1_000) return `${Math.round(value / 1_000)}k`;
  return String(Math.round(value));
}

const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December'];

function monthName(period) {
  const [year, month] = String(period).split('-');
  return `${MONTHS[Number(month) - 1] ?? period} ${year}`;
}

/**
 * Sales by month.
 *
 * The bars alone answer "was this month bigger than that one". Everything a
 * reader then wants — what it was worth, how many invoices it took, what that
 * averages, and whether it went up or down on the month before — is on hover,
 * because putting it on the chart would be six numbers per bar and no chart.
 */
function trendChart(rows) {
  if (!rows.length) return el('div', { class: 'empty', text: 'No sales in the last year.' });

  const width = 760;
  const height = 230;
  const pad = { top: 16, right: 14, bottom: 30, left: 52 };
  const max = Math.max(...rows.map((r) => r.sales || 0), 1);
  const innerW = width - pad.left - pad.right;
  const innerH = height - pad.top - pad.bottom;
  const step = innerW / rows.length;
  const barW = Math.max(6, Math.min(46, step - 12));
  const best = rows.reduce((top, r) => ((r.sales || 0) > (top.sales || 0) ? r : top), rows[0]);

  const svg = svgEl('svg', {
    viewBox: `0 0 ${width} ${height}`,
    class: 'chart-svg',
    role: 'img',
    'aria-label': `Sales by month, ${rows.length} months, highest ${money(best.sales)}`,
  });

  // Gridlines first, so the bars sit on top of them. Four is enough to read a
  // height against; more turns the card into graph paper.
  for (let i = 0; i <= 4; i += 1) {
    const value = (max / 4) * i;
    const y = pad.top + innerH - (innerH / 4) * i;
    svg.append(svgEl('line', {
      x1: pad.left, x2: width - pad.right, y1: y, y2: y, class: 'chart-grid',
    }));
    svg.append(svgEl('text', {
      x: pad.left - 10, y: y + 3.5, 'text-anchor': 'end', class: 'chart-axis',
    }, i === 0 ? '0' : shortMoney(value)));
  }

  const tip = el('div', { class: 'chart-tip', hidden: true });
  const wrap = el('div', { class: 'chart' }, [svg, tip]);

  const show = (row, index, hit, bar) => {
    const previous = index > 0 ? rows[index - 1] : null;
    const change = previous && previous.sales
      ? ((row.sales - previous.sales) / previous.sales) * 100
      : null;
    const average = row.invoices ? row.sales / row.invoices : 0;

    clear(tip);
    tip.append(
      el('p', { class: 'chart-tip-head', text: monthName(row.period) }),
      tipRow('Sales', money(row.sales), 'dot'),
      tipRow('Invoices', count(row.invoices)),
      tipRow('Average invoice', money(average)),
      change === null
        ? tipRow('Change', 'first month shown', 'muted')
        // The arrow is an element, not a character: the row's class turns it
        // over for a fall, and it inherits the row's green or red.
        : tipRow(`vs ${monthName(previous.period).split(' ')[0]}`, [
          el('span', { class: 'trend-arrow', 'aria-hidden': 'true' }),
          `${Math.abs(change).toFixed(1)}%`,
        ], change >= 0 ? 'up' : 'down'),
      row === best ? el('p', { class: 'chart-tip-note', text: 'Best month shown' }) : null,
    );

    // Placed from real positions on screen, so it stays correct however the SVG
    // has been scaled to the card. Centred on the column, but sitting above the
    // *bar* rather than above the plot — anchoring to the column would park the
    // tooltip at the top of the chart even for a month that barely registers.
    const column = hit.getBoundingClientRect();
    const top = bar.getBoundingClientRect();
    const host = wrap.getBoundingClientRect();
    tip.hidden = false;

    const left = column.left - host.left + column.width / 2 - tip.offsetWidth / 2;
    tip.style.left = `${Math.max(4, Math.min(left, host.width - tip.offsetWidth - 4))}px`;

    // Above the bar, or just below its top edge when there is no room above.
    const above = top.top - host.top - tip.offsetHeight - 10;
    tip.style.top = `${above >= 4 ? above : top.top - host.top + 10}px`;
  };

  const hide = () => { tip.hidden = true; };

  rows.forEach((row, i) => {
    const barH = Math.max(2, ((row.sales || 0) / max) * innerH);
    const x = pad.left + step * i + (step - barW) / 2;
    const group = svgEl('g', { class: 'chart-bar' });

    // The band, then the bar, then a transparent column that catches the
    // pointer: a lean month is six pixels tall, and hovering it should not
    // require hitting six pixels.
    const value = svgEl('rect', {
      x, y: pad.top + innerH - barH, width: barW, height: barH,
      rx: 4, class: 'chart-value',
    });
    group.append(
      svgEl('rect', {
        x: pad.left + step * i + 2, y: pad.top,
        width: step - 4, height: innerH, rx: 6, class: 'chart-band',
      }),
      value,
    );

    const hit = svgEl('rect', {
      x: pad.left + step * i, y: pad.top, width: step, height: innerH,
      fill: 'transparent', class: 'chart-hit', tabindex: '0', role: 'button',
      'aria-label': `${monthName(row.period)}: ${money(row.sales)} from `
        + `${row.invoices} invoices`,
    });
    hit.addEventListener('mouseenter', () => show(row, i, hit, value));
    hit.addEventListener('focus', () => show(row, i, hit, value));
    hit.addEventListener('mouseleave', hide);
    hit.addEventListener('blur', hide);
    group.append(hit);
    svg.append(group);

    svg.append(svgEl('text', {
      x: pad.left + step * i + step / 2, y: height - 10,
      'text-anchor': 'middle', class: 'chart-axis',
    }, row.period.slice(2).replace('-', '/')));
  });

  svg.addEventListener('mouseleave', hide);
  return wrap;
}

/** `value` is a string, or a list of nodes when the figure carries an icon. */
function tipRow(label, value, tone = '') {
  return el('div', { class: `chart-tip-row ${tone}`.trim() }, [
    tone === 'dot' ? el('span', { class: 'swatch' }) : null,
    el('span', { class: 'k', text: label }),
    el('span', { class: 'v' }, [].concat(value)),
  ]);
}

export const skeleton = 'stats';

export async function render(container) {
  setTitle('Dashboard');
  watching?.();
  watching = onChange(
    ['invoice:created', 'invoice:cancelled', 'collection:created',
     'purchase:created', 'return:created', 'stock:changed'],
    () => {
      if ((window.location.hash.slice(1) || '/').split('?')[0] !== '/overview') return;
      const host = page();
      host.replaceChildren();
      return render(host);
    },
    { wait: REFRESH_MS },
  );

  const data = await api.get('/reports/dashboard');
  const ar = data.receivable || {};
  const stock = data.stock || {};
  const overdue = ar.over_90 || 0;

  container.append(
    el('div', { class: 'stat-grid' }, [
      stat('Receivables', money(ar.total),
        `${count(ar.open_invoices)} open invoices · ${count(ar.customers)} customers`),
      stat('Over 90 days', money(overdue),
        overdue > 0 ? 'Needs chasing' : 'Nothing badly overdue',
        overdue > 0 ? 'danger' : 'ok'),
      stat('Sales this month', money(data.month?.sales),
        `${count(data.month?.invoices)} invoices`),
      stat('Sales this year', money(data.year?.sales), 'Net of discounts'),
      stat('Stock value', money(stock.value), `${count(stock.items)} active items`),
      stat('Needs attention', count(stock.needs_attention),
        `${count(stock.depleted)} depleted · ${count(stock.expiring)} expiring`,
        stock.needs_attention ? 'warn' : ''),
    ]),

    card(data.trend_is_recent === false
      ? 'Sales, last 12 months with activity'
      : 'Sales, last 12 months',
      trendChart(data.sales_trend || [])),

    el('div', { style: 'display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:18px' }, [
      card('Latest invoices', dataTable([
        { key: 'inv_no', label: 'Number', class: 'mono' },
        { key: 'customer_name', label: 'Customer' },
        { key: 'inv_date', label: 'Date', render: (r) => date(r.inv_date) },
        { key: 'net_amount', label: 'Amount', align: 'right', render: (r) => money(r.net_amount) },
        { key: 'status', label: '', render: (r) => statusTag(r.status) },
      ], data.recent_invoices || [], {
        onRowClick: (row) => { window.location.hash = `#/invoices/${row.inv_no}`; },
      }), [], { flush: true }),

      card('Latest payments', dataTable([
        { key: 'col_no', label: 'Number', class: 'mono' },
        { key: 'customer_name', label: 'Customer' },
        { key: 'col_date', label: 'Date', render: (r) => date(r.col_date) },
        { key: 'net_amount', label: 'Amount', align: 'right', render: (r) => money(r.net_amount) },
      ], data.recent_payments || [], {
        onRowClick: (row) => { window.location.hash = `#/collections/${row.col_no}`; },
      }), [], { flush: true }),
    ]),
  );
}
