

function(input, output, session){
  output$texto <- renderTyped({
    typed("Parts Description Generator", typeSpeed = 10 )
  })
  
  observe({
    if (is.null(input$excel$datapath)){
      shinyjs::disable("iniciar_proceso")
    } else {
      shinyjs::enable("iniciar_proceso")
    }
  })
  
  observeEvent(input$iniciar_proceso, {
    withProgress(message = "Iniciando proceso", {
      incProgress(amount = 0.1, message = "Generando requests")
      data <- readxl::read_excel(input$excel$datapath) |> 
        head(100)
      tabla_total <- data.frame()
      n <- 20
      total_filas <- nrow(data)
      size <- nrow(data) / 20
      for (i in seq(1, total_filas, by = n)) {
        bloque <- data[i:min(i + n - 1, total_filas), ]
        body <- list(
          contents = list( 
            list(
              parts = list(
                list(text = paste0(
                  "From the list. Please research each OEM part online and generate a standardized part description in the shape of a table, and return only the table, nothing else.
            Table should return recnum, part_name and part_description only\n\n",
                  paste(capture.output(print(bloque, row.names = FALSE)), collapse = "\n")
                ))
              )
            )
          )
        )
        response <- POST(
          url = paste0(url, "?key=", api_key),
          add_headers(`Content-Type` = "application/json"),
          body = toJSON(body, auto_unbox = TRUE),
          encode = "json"
        )
        # Parsear respuesta
        x <- fromJSON(content(response, "text", encoding = "UTF-8"))
        # Dividir en líneas y limpiar
        lineas <- unlist(strsplit(x$candidates$content$parts[[1]]$text, "\n"))
        lineas <- lineas[!grepl("^[-| ]+$", lineas)]
        # Convertir a tabla y acumular (con reintentos)
        intentos <- 0
        max_intentos <- 5
        tabla_parcial <- NULL
        while (is.null(tabla_parcial) && intentos < max_intentos) {
          intentos <- intentos + 1
          tabla_parcial <- tryCatch({
            read.table(
              text = lineas,
              sep = "|",
              header = TRUE,
              strip.white = TRUE,
              fill = TRUE,
              stringsAsFactors = FALSE
            ) |> 
              setNames(c("x", "recnum", "par_name", "part_desc", "x1"))
          }, error = function(e) {
            message("Intento ", intentos, " fallido al procesar bloque ", i, ": ", e$message)
            return(NULL)
          })
          if (is.null(tabla_parcial) && intentos < max_intentos) {
            Sys.sleep(1)  
          }
        }
        if (!is.null(tabla_parcial)) {
          tabla_parcial[] <- lapply(tabla_parcial, as.character)
          tabla_total <- bind_rows(tabla_total, tabla_parcial)
        }
        incProgress(amount = size, message = "Generando requests")
      }
      
      output$tabla <- renderReactable({
        tabla_total |> 
          reactable(
            highlight = T,             
            striped = T,             
            theme = nytimes(centered = TRUE, header_font_size = 11
                            #,background_color = "transparent"
            ),             
            defaultPageSize = 8,             
            defaultColDef = colDef(headerStyle = list(background = "#4661c2", color = "#fff",fontWeight = 600))
          )
      })
      
      data <- tabla_total
      
      output$downloadData <- downloadHandler(
        filename = function() {
          paste("parts data-", Sys.Date(), ".xlsx", sep="")
        },
        content = function(file) {
          writexl::write_xlsx(data, file)
        }
      )
      
    })
  })
}


