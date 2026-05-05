library(shiny)
library(DT)
library(shinyjs)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || is.na(x)) y else x
}

initial_responses <- data.frame(
  row_id = c(
    "5086d970-bea3-11e9-ad23-91bad5638bcb",
    "443cdd8c-c014-11e9-bbe6-e73bd2ce8807",
    "45511d6e-c014-11e9-bbe6-e73bd2ce8807",
    "4642e0ea-c014-11e9-bbe6-e73bd2ce8807",
    "47888130-c014-11e9-bbe6-e73bd2ce8807",
    "47888131-c014-11e9-bbe6-e73bd2ce8807",
    "4889d520-c014-11e9-bbe6-e73bd2ce8807",
    "4889d521-c014-11e9-bbe6-e73bd2ce8807",
    "499d1aee-c014-11e9-bbe6-e73bd2ce8807",
    "4ac24aa2-c014-11e9-bbe6-e73bd2ce8807"
  ),
  date = rep("14-08-2019", 10),
  name = c(
    "Niels", "Theo", "Doris", "Mark", "Bruno",
    "@(-.-)@", "Niels", "Doris", "Hugo", "Sally"
  ),
  sex = c("M", "M", "F", "M", "M", "M", "F", "F", "M", "M"),
  age = c(31, 26, 47, 16, 64, 26, 57, 36, 59, 53),
  comment = c(
    "Hello World!", "Great!", "No comment", "Thank You!", "",
    ":-)", "", "Nice!", "", "Sucks!"
  ),
  stringsAsFactors = FALSE
)

empty_responses <- initial_responses[0, ]

labelMandatory <- function(label) {
  tagList(label, span("*", class = "mandatory_star"))
}

row_payload <- function(row) {
  as.list(row[c("row_id", "date", "name", "sex", "age", "comment")])
}

rows_from_api <- function(rows) {
  if (length(rows) == 0) {
    return(empty_responses)
  }

  do.call(
    rbind,
    lapply(rows, function(row) {
      data.frame(
        row_id = as.character(row$row_id %||% ""),
        date = as.character(row$date %||% ""),
        name = as.character(row$name %||% ""),
        sex = as.character(row$sex %||% ""),
        age = as.integer(row$age %||% NA_integer_),
        comment = as.character(row$comment %||% ""),
        stringsAsFactors = FALSE
      )
    })
  )
}

appCSS <- "
  .mandatory_star { color: red; }
  .action-row { display: flex; flex-wrap: wrap; gap: 8px; }
  .action-row .btn { min-width: 88px; }
  .api-status { margin-top: 12px; }
  .modal-dialog { width: 400px; max-width: calc(100vw - 24px); }
  .shiny-split-layout > div { overflow: visible; }
"

apiJavaScript <- "
(function () {
  // Replace with the deployed Worker URL after running `npm run worker:deploy`.
  const WORKER_URL = 'https://shinylive-d1-datatable-api.housing-bermuda.workers.dev';

  // Soft barrier against random callers. Anyone who views the page source
  // can read this value, so it is not a substitute for real authentication.
  // Use the same value as the SHARED_SECRET set with `wrangler secret put`.
  const SHARED_SECRET = 'dbdba41c5ea4e71393dbe6ab4c5c8b0f103704ccde44616714b3af2021f08784';

  const isLocal = ['localhost', '127.0.0.1'].includes(window.location.hostname);
  const endpoint = (isLocal ? 'http://localhost:8787' : WORKER_URL) + '/api/responses';

  async function request(method, payload) {
    const options = {
      method,
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': SHARED_SECRET
      },
      cache: 'no-store'
    };

    if (payload !== undefined) {
      options.body = JSON.stringify(payload);
    }

    const response = await fetch(endpoint, options);
    const text = await response.text();
    const data = text ? JSON.parse(text) : {};

    if (!response.ok) {
      throw new Error(data.error || response.statusText);
    }

    return data;
  }

  function emitError(error) {
    Shiny.setInputValue(
      'api_error',
      { message: error.message || String(error), nonce: Date.now() },
      { priority: 'event' }
    );
  }

  window.SqlTableApi = {
    async load() {
      try {
        const data = await request('GET');
        Shiny.setInputValue(
          'api_rows',
          { rows: data.rows || [], nonce: Date.now() },
          { priority: 'event' }
        );
      } catch (error) {
        emitError(error);
      }
    },
    async create(row) {
      try {
        await request('POST', { action: 'create', row });
        await this.load();
      } catch (error) {
        emitError(error);
      }
    },
    async update(row) {
      try {
        await request('PUT', { action: 'update', row });
        await this.load();
      } catch (error) {
        emitError(error);
      }
    },
    async delete(rowIds) {
      try {
        await request('DELETE', { row_ids: rowIds });
        await this.load();
      } catch (error) {
        emitError(error);
      }
    },
    async copy(rowIds) {
      try {
        await request('POST', { action: 'copy', row_ids: rowIds });
        await this.load();
      } catch (error) {
        emitError(error);
      }
    }
  };

  Shiny.addCustomMessageHandler('api-load', _message => window.SqlTableApi.load());
  Shiny.addCustomMessageHandler('api-create', row => window.SqlTableApi.create(row));
  Shiny.addCustomMessageHandler('api-update', row => window.SqlTableApi.update(row));
  Shiny.addCustomMessageHandler('api-delete', rowIds => window.SqlTableApi.delete(rowIds));
  Shiny.addCustomMessageHandler('api-copy', rowIds => window.SqlTableApi.copy(rowIds));

  $(document).on('shiny:connected', function () {
    window.SqlTableApi.load();
  });
})();
"

ui <- fluidPage(
  shinyjs::useShinyjs(),
  shinyjs::inlineCSS(appCSS),
  tags$head(tags$script(HTML(apiJavaScript))),
  fluidRow(
    column(
      width = 12,
      div(
        class = "action-row",
        actionButton("add_button", "Add", icon("plus")),
        actionButton("edit_button", "Edit", icon("edit")),
        actionButton("copy_button", "Copy", icon("copy")),
        actionButton("delete_button", "Delete", icon("trash-alt")),
        actionButton("refresh_button", "Refresh", icon("sync"))
      )
    )
  ),
  uiOutput("api_status"),
  br(),
  fluidRow(
    column(width = 12, dataTableOutput("responses_table", width = "100%"))
  )
)

server <- function(input, output, session) {
  responses <- reactiveVal(initial_responses)
  api_error <- reactiveVal(NULL)
  edit_row_id <- reactiveVal(NULL)

  fieldsMandatory <- c("name", "sex")
  fieldsAll <- c("name", "sex", "age", "comment")

  observeEvent(input$api_rows, {
    responses(rows_from_api(input$api_rows$rows))
    api_error(NULL)
  })

  observeEvent(input$api_error, {
    api_error(input$api_error$message)
  })

  output$api_status <- renderUI({
    if (is.null(api_error())) {
      return(NULL)
    }

    div(class = "api-status alert alert-warning", api_error())
  })

  observe({
    mandatoryFilled <- vapply(
      fieldsMandatory,
      function(x) {
        !is.null(input[[x]]) && nzchar(input[[x]])
      },
      logical(1)
    )

    shinyjs::toggleState(id = "submit", condition = all(mandatoryFilled))
    shinyjs::toggleState(id = "submit_edit", condition = all(mandatoryFilled))
  })

  show_warning <- function(message) {
    showModal(modalDialog(title = "Warning", message, easyClose = TRUE))
  }

  entry_form <- function(button_id, values = NULL) {
    defaults <- list(name = "", sex = "", age = 1, comment = "")
    values <- modifyList(defaults, as.list(values))

    showModal(
      modalDialog(
        div(
          id = "entry_form",
          fluidPage(
            fluidRow(
              splitLayout(
                cellWidths = c("250px", "100px"),
                cellArgs = list(style = "vertical-align: top"),
                textInput("name", labelMandatory("Name"), value = values$name),
                selectInput(
                  "sex",
                  labelMandatory("Sex"),
                  multiple = FALSE,
                  choices = c("", "M", "F"),
                  selected = values$sex
                )
              ),
              sliderInput(
                "age",
                "Age",
                0,
                100,
                value = as.numeric(values$age),
                ticks = TRUE,
                width = "354px"
              ),
              textAreaInput(
                "comment",
                "Comment",
                value = values$comment,
                height = 100,
                width = "354px"
              ),
              helpText(labelMandatory(""), "Mandatory field."),
              actionButton(button_id, "Submit")
            )
          )
        ),
        easyClose = TRUE,
        footer = NULL
      )
    )
  }

  formData <- reactive({
    data.frame(
      row_id = edit_row_id() %||% "",
      date = format(Sys.Date(), format = "%d-%m-%Y"),
      name = input$name,
      sex = input$sex,
      age = input$age,
      comment = input$comment,
      stringsAsFactors = FALSE
    )
  })

  observeEvent(input$refresh_button, {
    session$sendCustomMessage("api-load", list())
  })

  observeEvent(input$add_button, {
    edit_row_id(NULL)
    entry_form("submit")
  })

  observeEvent(input$submit, {
    session$sendCustomMessage("api-create", row_payload(formData()))
    shinyjs::reset("entry_form")
    removeModal()
  })

  observeEvent(input$delete_button, {
    selected <- input$responses_table_rows_selected

    if (length(selected) < 1) {
      show_warning("Please select row(s).")
      return()
    }

    session$sendCustomMessage("api-delete", responses()[selected, "row_id"])
  })

  observeEvent(input$copy_button, {
    selected <- input$responses_table_rows_selected

    if (length(selected) < 1) {
      show_warning("Please select row(s).")
      return()
    }

    session$sendCustomMessage("api-copy", responses()[selected, "row_id"])
  })

  observeEvent(input$edit_button, {
    selected <- input$responses_table_rows_selected

    if (length(selected) > 1) {
      show_warning("Please select only one row.")
      return()
    }

    if (length(selected) < 1) {
      show_warning("Please select a row.")
      return()
    }

    current <- responses()
    selected_row <- current[selected, , drop = FALSE]
    edit_row_id(selected_row$row_id)
    entry_form("submit_edit", selected_row[fieldsAll])
  })

  observeEvent(input$submit_edit, {
    session$sendCustomMessage("api-update", row_payload(formData()))
    edit_row_id(NULL)
    removeModal()
  })

  output$responses_table <- DT::renderDataTable({
    table <- responses()[c("date", "name", "sex", "age", "comment")]
    names(table) <- c("Date", "Name", "Sex", "Age", "Comment")

    datatable(
      table,
      rownames = FALSE,
      selection = "multiple",
      options = list(searching = FALSE, lengthChange = FALSE)
    )
  })
}

shinyApp(ui = ui, server = server)
