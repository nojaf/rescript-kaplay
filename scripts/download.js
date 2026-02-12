const args = Bun.argv;
const lastArg = args[args.length - 1];

if (lastArg.endsWith(".js")) {
  console.log("Add a pokemon name as last argument to download the sprite");
  process.exit(1);
} else {
  const name = lastArg;
  const response = await fetch(`https://img.pokemondb.net/sprites/red-blue/normal/${name}.png`);
  await Bun.write(`packages/samples/public/sprites/${name}-rb.png`, await response.arrayBuffer());
  console.log(`Sprite downloaded for ${name}`);
}
