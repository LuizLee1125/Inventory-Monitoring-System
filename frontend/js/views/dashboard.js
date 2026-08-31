// Landing screen: receivables, sales, stock health, recent activity.

import { api } from '../api.js';
import { card, count, date, dataTable, el, money, stat, statusTag } from '../ui.js';
import { setTitle } from '../app.js';

function trendChart(rows) {
  if (!rows.length) return el('div', { class: 'empty', text: 'No sales in the last year.' });

  const width = 760;
  const height = 190;
  const padding = { top: 14, right: 12, bottom: 26, left: 12 };
  const max = Math.max(...rows.map((r) => r.sales || 0), 1);
  const innerW = width - padding.left - padding.right;
  const innerH = height - padding.top - padding.bottom;
  const barW = Math.max(6, innerW / rows.length - 8);

  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
  svg.setAttribute('width', '100%');
  svg.setAttribute('style', 'display:block');

  rows.forEach((row, i) => {
    const barH = Math.max(2, ((row.sales || 0) / max) * innerH);
    const x = padding.left + (innerW / rows.length) * i + 4;
    const y = padding.top + innerH - barH;

    const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    rect.setAttribute('x', x);
    rect.setAttribute('y', y);
    rect.setAttribute('width', barW);
    rect.setAttribute('height', barH);
    rect.setAttribute('rx', '3');
    rect.setAttribute('fill', 'var(--primary)');
    rect.setAttribute('opacity', i === rows.length - 1 ? '1' : '0.72');
    const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
    title.textContent = `${row.period}: ${money(row.sales)} (${row.invoices} invoices)`;
    rect.append(title);
    svg.append(rect);

    const label = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    label.setAttribute('x', x + barW / 2);
    label.setAttribute('y', height - 8);
    label.setAttribute('text-anchor', 'middle');
    label.setAttribute('font-size', '10');
    label.setAttribute('fill', 'var(--text-faint)');
    label.textContent = row.period.slice(2).replace('-', '/');
    svg.append(label);
  });

  return svg;
}

export const skeleton = 'stats';

export async function render(container) {
  setTitle('Dashboard');
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
