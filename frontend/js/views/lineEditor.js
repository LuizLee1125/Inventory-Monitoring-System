// Shared line-item grid used by the invoice, purchase and return editors.
//
// It reproduces what the DOS screens did on rows 9-19: type a stock code, the
// description and price fill themselves in, the line total recalculates, and
// the running total sits at the bottom.

import { attachLookup, el, money, qty } from '../ui.js';

/**
 * @param {object} options
 *   priceField   - which stock price to default to ('price_a' … 'price_e'), or
 *                  'cost' for purchases
 *   showDiscounts- render the three discount columns
 *   checkStock   - warn when a quantity exceeds what is on hand. On for the
 *                  invoice editor, off for purchases and returns, which put
 *                  stock back rather than taking it
 *   onChange     - called after every recalculation with the subtotal
 */
export function lineEditor({ priceField = 'price_a', showDiscounts = true,
                             checkStock = false, onChange } = {}) {
  const body = el('tbody');
  const subtotalCell = el('span', { text: money(0) });
  const rows = [];

  const columns = [
    'Stock code', 'Description', 'Qty', 'Unit', 'Price',
    ...(showDiscounts ? ['Disc 1 %', 'Disc 2 %'] : []),
    'Total', '',
  ];

  function recalc() {
    let subtotal = 0;
    for (const row of rows) {
      if (row.removed) continue;
      const quantity = Number(row.qty.value || 0);
      const price = Number(row.price.value || 0);
      let total = quantity * price;
      if (showDiscounts) {
        for (const node of [row.disc1, row.disc2]) {
          const pct = Number(node.value || 0);
          if (pct) total *= (1 - pct / 100);
        }
      }
      row.total = Math.round(total * 100) / 100;
      row.totalCell.textContent = money(row.total);
      subtotal += row.total;
    }
    subtotal = Math.round(subtotal * 100) / 100;
    subtotalCell.textContent = money(subtotal);
    onChange?.(subtotal);
    return subtotal;
  }

  function addRow(preset = {}) {
    const code = el('input', {
      placeholder: 'code', style: 'text-transform:uppercase', value: preset.stock_code || '',
    });
    const description = el('input', { readonly: true, value: preset.description || '' });
    const quantity = el('input', { type: 'number', step: '0.01', min: '0', value: preset.qty ?? '' });
    const unit = el('input', { value: preset.unit || '', style: 'width:70px' });
    const price = el('input', { type: 'number', step: '0.01', value: preset.unit_price ?? '' });
    const disc1 = el('input', { type: 'number', step: '0.01', value: preset.disc1 ?? '' });
    const disc2 = el('input', { type: 'number', step: '0.01', value: preset.disc2 ?? '' });
    const totalCell = el('td', { class: 'total', text: money(0) });
    const stockWarning = el('span', { class: 'line-warn', hidden: true });

    const row = {
      code, description, qty: quantity, unit, price, disc1, disc2, totalCell,
      removed: false,
      // Filled in by the lookup. `null` means nothing has been picked on this
      // row yet, which is not the same as an item with nothing on hand.
      onHand: null, allowOversell: true, itemUnit: '',
    };

    /**
     * Say, before the save, that this line is taking more than is there.
     *
     * Advisory only — the server decides, and it decides on the quantities as
     * they are at the moment of the save rather than as they were when this
     * row's lookup ran. That is the whole point: this warning can be *wrong*
     * in both directions by the time Save is pressed, because somebody else is
     * invoicing at the same counter. It exists to catch the ordinary case
     * early, not to be authoritative.
     */
    function checkQuantity() {
      if (!checkStock || row.onHand === null) return;
      const wanted = Number(quantity.value || 0);
      const over = wanted > Math.max(0, row.onHand);
      quantity.classList.toggle('over', over);
      stockWarning.hidden = !over;
      if (!over) return;
      const short = Math.round((wanted - Math.max(0, row.onHand)) * 100) / 100;
      stockWarning.textContent = row.allowOversell
        ? `${qty(Math.max(0, row.onHand))} on hand · ${qty(short)} short`
        : `Only ${qty(Math.max(0, row.onHand))} on hand — this item cannot be oversold`;
      stockWarning.classList.toggle('blocking', !row.allowOversell);
    }

    const remove = el('button', {
      class: 'btn ghost sm', text: '✕', title: 'Remove line',
      onClick: () => {
        row.removed = true;
        tr.remove();
        if (!rows.some((r) => !r.removed)) addRow();
        recalc();
      },
    });

    const cells = [
      el('td', { style: 'width:150px;position:relative' }, [code]),
      el('td', {}, [description]),
      el('td', { class: 'num', style: 'width:95px' }, [quantity, stockWarning]),
      el('td', { style: 'width:80px' }, [unit]),
      el('td', { class: 'num', style: 'width:110px' }, [price]),
      ...(showDiscounts ? [
        el('td', { class: 'num', style: 'width:80px' }, [disc1]),
        el('td', { class: 'num', style: 'width:80px' }, [disc2]),
      ] : []),
      totalCell,
      el('td', { style: 'width:34px' }, [remove]),
    ];

    const tr = el('tr', {}, cells);
    body.append(tr);
    rows.push(row);

    attachLookup(code, '/stock/lookup', {
      format: (item) => item.name,
      meta: (item) => `${qty(item.qty_on_hand)} ${item.unit || ''}`.trim(),
      onPick: (item) => {
        description.value = item.name;
        unit.value = item.unit || '';
        row.onHand = Number(item.qty_on_hand || 0);
        // Absent on a server that predates the column, and the safe reading of
        // absent is the column's own default: selling was always allowed
        // before it existed.
        row.allowOversell = item.allow_oversell === undefined
          ? true : Boolean(item.allow_oversell);
        if (!price.value) {
          price.value = Number(item[priceField] ?? item.price_a ?? 0).toFixed(2);
        }
        if (!quantity.value) quantity.value = 1;
        quantity.focus();
        quantity.select();
        checkQuantity();
        recalc();
        // Typing into the last row starts a new one, as the DOS grid did.
        if (row === rows[rows.length - 1]) addRow();
      },
    });

    for (const node of [quantity, price, disc1, disc2]) {
      node.addEventListener('input', recalc);
    }
    quantity.addEventListener('input', checkQuantity);
    row.check = checkQuantity;
    quantity.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') { event.preventDefault(); price.focus(); }
    });

    return row;
  }

  const table = el('table', { class: 'lines' }, [
    el('thead', {}, [el('tr', {}, columns.map((label, i) =>
      el('th', { class: i >= 2 && i <= 7 ? 'num' : '' }, [label])))]),
    body,
  ]);

  const node = el('div', {}, [
    el('div', { style: 'overflow-x:auto' }, [table]),
    el('div', { class: 'toolbar', style: 'margin:10px 0 0' }, [
      el('button', { class: 'btn sm', text: '+ Add line', onClick: () => addRow() }),
      el('span', { class: 'spacer' }),
      el('span', { class: 'hint' }, ['Subtotal ', subtotalCell]),
    ]),
  ]);

  addRow();

  return {
    node,
    recalc,
    addRow,

    /** The stock codes currently typed on the grid, de-duplicated. */
    codes() {
      return [...new Set(rows
        .filter((row) => !row.removed && row.code.value.trim())
        .map((row) => row.code.value.trim().toUpperCase()))];
    },

    /**
     * Re-apply on-hand figures fetched since the rows were typed.
     *
     * This is what makes the editor live. A clerk half way through a long
     * invoice is looking at quantities read minutes ago, and the person at the
     * next counter has been selling from the same shelf the whole time. Handed
     * `{CODE: {qty_on_hand, allow_oversell}}` the grid re-checks every row, so
     * the warning appears while there is still time to do something about it
     * rather than in a toast after the save.
     *
     * Only the *warning* moves. Nothing the clerk typed is touched — quantities,
     * prices and discounts are theirs, and a screen that edits itself under
     * somebody's hands is worse than one that is out of date.
     */
    applyStock(byCode) {
      for (const row of rows) {
        if (row.removed) continue;
        const fresh = byCode[row.code.value.trim().toUpperCase()];
        if (!fresh) continue;
        row.onHand = Number(fresh.qty_on_hand || 0);
        row.allowOversell = fresh.allow_oversell === undefined
          ? true : Boolean(fresh.allow_oversell);
        row.check?.();
      }
    },

    /** Lines ready to send to the API. */
    getLines() {
      return rows
        .filter((row) => !row.removed && row.code.value.trim() && Number(row.qty.value || 0) > 0)
        .map((row) => ({
          stock_code: row.code.value.trim().toUpperCase(),
          qty: Number(row.qty.value || 0),
          unit: row.unit.value.trim(),
          unit_price: Number(row.price.value || 0),
          unit_cost: Number(row.price.value || 0),
          disc1: Number(row.disc1.value || 0),
          disc2: Number(row.disc2.value || 0),
        }));
    },
    subtotal: () => recalc(),
  };
}
