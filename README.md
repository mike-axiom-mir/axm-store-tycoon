# AXM Tiny Mart 3D — v0.1

A small first-person 3D store-tycoon prototype built from the uploaded AXM Connected Monolith v0.4.42 capability body.

## What the first slice does

You begin in a tiny, mostly empty convenience store with two bare shelves, a checkout counter, a supplier pad and an upgrade terminal.

Core loop:

1. Look at the **Supplier Pad** and press **E / gamepad A** to buy a mystery crate.
2. Look at the delivered crate and press **E / A** to reveal three RNG product lots.
3. **R / gamepad Y** cycles your selected back-room lot.
4. Look at an empty shelf and press **E / A** to stock it. Products become visible on the shelf.
5. Customers enter, browse stocked shelves, carry purchases to checkout and leave.
6. Look at stocked goods and press **Q / gamepad X** to cycle 0%, 10%, 25%, or 50% discount.
7. Perishable stock ages in the back room and on shelves. Expired stock becomes waste and hurts reputation.
8. Look at the upgrade terminal and press **E / A** to buy the next physical store improvement.

Daily RNG events can alter traffic, product demand, or crate price.

## Visual upgrades in v0.1

- Warm ceiling lights
- Side-wall shelf
- Glass display fridge with slower expiry
- Neon storefront/sign makeover
- Cozy rug + plants
- Supplier rarity scanner

## Controls

- `WASD` / left stick — move
- Mouse / right stick — look
- `E` / A — interact
- `Q` / X — change shelf discount
- `R` / Y — cycle selected back-room stock
- `Esc` — release/capture mouse

## Run it

This is a **Godot 4 project**. A Web export is built automatically in GitHub Actions so the same 3D game can be inspected in a browser. Godot 4.3+ is the intended engine family.

## Continuous visual test loop

GitHub Actions builds a Web export, launches it in Chromium with Playwright, captures a real rendered screenshot, and uploads the screenshot + browser build as workflow artifacts. This is the shared visual evidence loop for iteration; a green code-only build is not treated as visual proof.
