@scope("import.meta.env")
external baseUrl: string = "BASE_URL"

@scope("window")
external innerWidth: float = "innerWidth"

@scope("window")
external innerHeight: float = "innerHeight"

let scale = min(
  // Don't scale larger than 1.5
  1.5,
  // Scale via width or height
  min(innerWidth / 800., innerHeight / 400.),
)
