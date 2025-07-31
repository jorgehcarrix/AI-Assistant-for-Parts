
page_sidebar(
  shinyjs::useShinyjs(),
  title = "Parts Desc",
  sidebar = sidebar(
    "Contenido del sidebar",
    fileInput("excel", "Upload your excel parts file", accept = ".xlsx"),
    actionButton("iniciar_proceso", "Ejecutar", icon = icon("globe")),
    downloadButton("downloadData", "Download results",
                   icon = icon("file-excel"))
  ),
  theme = bs_theme(
    version = 5,
    base_font = font_google("Roboto"),
    bg = "#fff",
    fg = "#000",
    "navbar-bg" = "#000"
  ),
  div(
    style = "text-align: center; margin-top: 50px;",
    h1(
      style = "color: grey; font-size: 60px;",
      typedOutput("texto")
    ),
    br(),
    reactableOutput("tabla")
  )
)