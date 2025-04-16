const name = "flareon";
const response = await fetch(`https://img.pokemondb.net/sprites/red-blue/normal/${name}.png`);
await Bun.write(`public/sprites/${name}-rb.png`, await response.arrayBuffer());