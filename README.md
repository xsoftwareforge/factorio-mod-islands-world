# Islands World (Factorio 2.0)
Map generator preset "Many islands" that creates many small islands. The mod ensures iron, copper, stone, and coal exist on the spawn island.

## Features
- New map-gen preset "Many islands" (id: `kap_islands`).
- Starting resources are placed on the spawn island (iron, copper, stone, coal).
- Creates small land patches if needed so resources do not spawn in water.
- Keeps checking during chunk generation until all four resources are present.

## Usage
- New game: choose the map-gen preset "Many islands".
- Existing save: run `/enable_islands_world` once to switch elevation and place missing starting resources.

## Compatibility
- Factorio 2.0
- Locales: en, ja

## License
MIT. See `LICENSE`.