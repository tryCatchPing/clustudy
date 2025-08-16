# RectNorm

- Domain: [0..1]
- Invariants: x0 < x1, y0 < y1
- Normalize: values should be clamped into [0,1] and swapped if needed before persist.

Used by `LinkEntity` to store link regions relative to page size.
