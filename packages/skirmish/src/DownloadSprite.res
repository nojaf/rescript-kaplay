type pokemonSprites = {front: string, back: string}

let decodePokemonSprite = (json: JSON.t): option<pokemonSprites> => {
  switch json {
  | JSON.Object(dict{
      "sprites": JSON.Object(dict{
        "back_default": JSON.String(back),
        "front_default": JSON.String(front),
      }),
    }) =>
    Some({front, back})
  | _ => None
  }
}

let isNumeric = (str: string): bool => {
  let parsed = Float.parseFloat(str)
  !Float.isNaN(parsed)
}

let downloadSprite = async (spriteUrl: string, fileName: string): unit => {
  let imageResponse = await RescriptBun.Globals.fetch(spriteUrl)

  if !RescriptBun.Globals.Response.ok(imageResponse) {
    let status = RescriptBun.Globals.Response.status(imageResponse)
    let statusText = RescriptBun.Globals.Response.statusText(imageResponse)
    Console.error(`Failed to fetch sprite image`)
    Console.error(`URL: ${spriteUrl}`)
    Console.error(`Status: ${status->Int.toString} ${statusText}`)
    RescriptBun.Process.exitWithCode(RescriptBun.Process.process, 1)
  } else {
    let blob = await imageResponse->RescriptBun.Globals.Response.blob

    // Convert Blob to Buffer
    let arrayBuffer = await blob->RescriptBun.Globals.Blob.arrayBuffer
    let buffer = RescriptBun.Buffer.fromArrayBuffer(arrayBuffer)

    // Create Sharp instance and process image
    let sharpInstance = Sharp.sharpFromBuffer(buffer)
    let trimmed = sharpInstance->Sharp.trim
    let resized =
      trimmed
      ->Sharp.resize({
        width: 32,
        height: 32,
        fit: "contain",
        background: {r: 0, g: 0, b: 0, alpha: 0},
      })
      ->Sharp.png

    // Determine output path
    let outputPath = RescriptBun.Path.join([
      RescriptBun.Global.dirname,
      "..",
      "public",
      "sprites",
      fileName,
    ])

    await resized->Sharp.toFile(outputPath)
    Console.log(`Created sprite for ${fileName}`)
  }
}

let main = async (identifier: string, outputPath: option<string>): unit => {
  let trimmedIdentifier = identifier->String.trim
  let url = `https://pokeapi.co/api/v2/pokemon/${trimmedIdentifier}/`

  try {
    let response = await RescriptBun.Globals.fetch(url)

    if !RescriptBun.Globals.Response.ok(response) {
      let status = RescriptBun.Globals.Response.status(response)
      let statusText = RescriptBun.Globals.Response.statusText(response)
      let responseBody = try {
        Some(await response->RescriptBun.Globals.Response.text)
      } catch {
      | _ => None
      }

      Console.error(`Fetch failed for URL: ${url}`)
      Console.error(`Status: ${status->Int.toString} ${statusText}`)
      switch responseBody {
      | Some(body) => Console.error(`Response body: ${body}`)
      | None => ()
      }

      let helpText = isNumeric(trimmedIdentifier)
        ? `Invalid Pokemon ID: ${trimmedIdentifier}`
        : `Invalid Pokemon name: ${trimmedIdentifier}`
      Console.error(helpText)
      RescriptBun.Process.exitWithCode(RescriptBun.Process.process, 1)
    } else {
      let json = await response->RescriptBun.Globals.Response.json

      switch decodePokemonSprite(json) {
      | None => {
          let helpText = isNumeric(trimmedIdentifier)
            ? "Could not find Pokemon with that ID"
            : "Could not find Pokemon with that name"
          Console.error(`Error: ${helpText}`)
          Console.error(`URL: ${url}`)
          RescriptBun.Process.exitWithCode(RescriptBun.Process.process, 1)
        }
      | Some({front, back}) =>
        try {
          await downloadSprite(front, `${trimmedIdentifier}-front.png`)
          await downloadSprite(back, `${trimmedIdentifier}-back.png`)
          Console.log(`Created sprites for ${trimmedIdentifier}`)
        } catch {
        | exn => {
            Console.error(`Error during image processing`)
            Console.error(exn)
            RescriptBun.Process.exitWithCode(RescriptBun.Process.process, 1)
          }
        }
      }
    }
  } catch {
  | exn => {
      Console.error(`Error fetching Pokemon data`)
      Console.error(`URL: ${url}`)
      Console.error(exn)
      let helpText = isNumeric(trimmedIdentifier)
        ? `Invalid Pokemon ID: ${trimmedIdentifier}`
        : `Invalid Pokemon name: ${trimmedIdentifier}`
      Console.error(helpText)
      RescriptBun.Process.exitWithCode(RescriptBun.Process.process, 1)
    }
  }
}

let parseArgs = () => {
  let args = RescriptBun.Bun.argv
  // Skip the first two args (bun executable and script path)
  let scriptArgs = Array.slice(args, ~start=2)

  switch scriptArgs[0] {
  | None => {
      Console.error("Error: Required parameter is missing. Provide a Pokemon name or ID.")
      RescriptBun.Process.exitWithCode(RescriptBun.Process.process, 1)
      None
    }
  | Some(identifier) => {
      let optionalPath = scriptArgs->Array.at(1)
      Some((identifier, optionalPath))
    }
  }
}

switch parseArgs() {
| None => ()
| Some((required, optionalPath)) => await main(required, optionalPath)
}
