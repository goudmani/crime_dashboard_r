library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(readr)
library(scales)

# ── Data ──────────────────────────────────────────────────────────────────────
crime_raw <- read_csv("data/processed/ucr_crime_1975_2015_processed.csv", show_col_types = FALSE)

# Clean city names (strip trailing state abbreviations for display)
crime <- crime_raw |>
  mutate(city = stringr::str_remove(department_name, ",.*$") |> trimws())

cities      <- sort(unique(crime$city))
year_min    <- min(crime$year)
year_max    <- max(crime$year)

crime_metrics <- c(
  "Violent Crime (per 100k)"  = "violent_per_100k",
  "Homicides (per 100k)"      = "homs_per_100k",
  "Rape (per 100k)"           = "rape_per_100k",
  "Robbery (per 100k)"        = "rob_per_100k",
  "Aggravated Assault (per 100k)" = "agg_ass_per_100k"
)

# ── Theme ─────────────────────────────────────────────────────────────────────
app_theme <- bs_theme(
  version      = 5,
  bootswatch   = "flatly",
  primary      = "#2C3E50",
  secondary    = "#18BC9C",
  base_font    = font_google("Inter"),
  heading_font = font_google("Inter", wght = 700)
)

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- page_navbar(
  title = span(
    bsicons::bs_icon("shield-fill-exclamation", size = "1.1em"),
    " U.S. Crime Dashboard (1975–2015)"
  ),
  theme = app_theme,
  fillable = TRUE,

  nav_panel(
    title = "Overview",
    icon  = bsicons::bs_icon("bar-chart-fill"),

    layout_sidebar(
      # ── Sidebar ────────────────────────────────────────────────────────────
      sidebar = sidebar(
        width = 280,
        bg    = "#f8f9fa",

        tags$h6(class = "text-muted fw-bold mb-3 text-uppercase",
                "Filters"),

        selectInput(
          "city",
          label = "City",
          choices  = cities,
          selected = "Chicago",
          multiple = FALSE
        ),

        sliderInput(
          "year_range",
          label = "Year Range",
          min   = year_min,
          max   = year_max,
          value = c(year_min, year_max),
          step  = 1,
          sep   = ""
        ),

        selectInput(
          "metric",
          label    = "Crime Metric",
          choices  = crime_metrics,
          selected = "violent_per_100k"
        ),

        hr(),
        tags$p(
          class = "text-muted small",
          "Source: FBI Uniform Crime Reports (UCR), 1975–2015. Rates are per 100,000 residents."
        )
      ),

      # ── Main content ────────────────────────────────────────────────────────
      layout_columns(
        col_widths = c(4, 4, 4),

        # Value boxes
        value_box(
          title    = "Average Rate - Per 100K",
          value    = textOutput("vb_avg"),
          showcase = bsicons::bs_icon("activity"),
          theme    = "primary"
        ),
        value_box(
          title    = "Peak Rate - Per 100K",
          value    = textOutput("vb_peak"),
          showcase = bsicons::bs_icon("graph-up-arrow"),
          theme    = "danger"
        ),
        value_box(
          title    = "Latest Rate - Per 100K",
          value    = textOutput("vb_latest"),
          showcase = bsicons::bs_icon("calendar-check"),
          theme    = "success"
        )
      ) |>
        tagAppendAttributes(style = "margin-bottom: 1rem;"),

      layout_columns(
        col_widths = c(7, 5),

        card(
          full_screen = TRUE,
          card_header(textOutput("trend_title")),
          card_body(plotOutput("trend_plot", height = "320px"))
        ),

        card(
          full_screen = TRUE,
          card_header("Top 10 Cities in Selected Year Range"),
          card_body(plotOutput("bar_plot", height = "320px"))
        )
      ),

      card(
        full_screen = TRUE,
        card_header("City Data Table"),
        card_body(
          DT::dataTableOutput("data_table")
        )
      )
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  # ── Reactive: filtered data for selected city ──────────────────────────────
  city_data <- reactive({
    crime |>
      filter(
        city  == input$city,
        year  >= input$year_range[1],
        year  <= input$year_range[2]
      ) |>
      arrange(year)
  })

  # ── Reactive: all-city data in year range (for bar chart) ──────────────────
  all_city_summary <- reactive({
    crime |>
      filter(
        year >= input$year_range[1],
        year <= input$year_range[2]
      ) |>
      group_by(city) |>
      summarise(avg_rate = mean(.data[[input$metric]], na.rm = TRUE), .groups = "drop") |>
      slice_max(avg_rate, n = 10)
  })

  # ── Value boxes ────────────────────────────────────────────────────────────
  output$vb_avg <- renderText({
    val <- mean(city_data()[[input$metric]], na.rm = TRUE)
    comma(round(val, 1))
  })

  output$vb_peak <- renderText({
    val <- max(city_data()[[input$metric]], na.rm = TRUE)
    comma(round(val, 1))
  })

  output$vb_latest <- renderText({
    d <- city_data()
    if (nrow(d) == 0) return("N/A")
    val <- tail(d[[input$metric]], 1)
    comma(round(val, 1))
  })

  # ── Trend plot ─────────────────────────────────────────────────────────────
  output$trend_title <- renderText({
    metric_label <- names(crime_metrics)[crime_metrics == input$metric]
    paste0(input$city, " — ", metric_label, " Over Time")
  })

  output$trend_plot <- renderPlot({
    d <- city_data()
    if (nrow(d) == 0) {
      return(ggplot() +
               annotate("text", x = 0.5, y = 0.5, label = "No data available",
                        size = 5, colour = "grey50") +
               theme_void())
    }

    metric_label <- names(crime_metrics)[crime_metrics == input$metric]

    ggplot(d, aes(x = year, y = .data[[input$metric]])) +
      geom_ribbon(aes(ymin = 0, ymax = .data[[input$metric]]),
                  fill = "#2C3E50", alpha = 0.12) +
      geom_line(colour = "#2C3E50", linewidth = 1.2) +
      geom_point(colour = "#18BC9C", size = 2.5) +
      scale_x_continuous(breaks = pretty_breaks(n = 8)) +
      scale_y_continuous(labels = comma) +
      labs(x = NULL, y = metric_label) +
      theme_minimal(base_size = 13) +
      theme(
        panel.grid.minor = element_blank(),
        axis.title.y     = element_text(size = 11, colour = "grey40")
      )
  })

  # ── Bar chart ──────────────────────────────────────────────────────────────
  output$bar_plot <- renderPlot({
    d <- all_city_summary()
    if (nrow(d) == 0) return(ggplot() + theme_void())

    metric_label <- names(crime_metrics)[crime_metrics == input$metric]

    d |>
      mutate(city = reorder(city, avg_rate),
             highlight = city == input$city) |>
      ggplot(aes(x = avg_rate, y = city, fill = highlight)) +
      geom_col(show.legend = FALSE) +
      scale_fill_manual(values = c("TRUE" = "#E74C3C", "FALSE" = "#95A5A6")) +
      scale_x_continuous(labels = comma) +
      labs(x = paste("Avg.", metric_label), y = NULL) +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank(),
            panel.grid.major.y = element_blank())
  })

  # ── Data table ─────────────────────────────────────────────────────────────
  output$data_table <- DT::renderDataTable({
    city_data() |>
      select(
        Year       = year,
        City       = city,
        Population = total_pop,
        `Violent / 100k`   = violent_per_100k,
        `Homicides / 100k` = homs_per_100k,
        `Rape / 100k`      = rape_per_100k,
        `Robbery / 100k`   = rob_per_100k,
        `Agg. Assault / 100k` = agg_ass_per_100k
      ) |>
      mutate(across(where(is.numeric) & !Year, ~ round(.x, 1)))
  },
  options = list(
    pageLength = 10,
    scrollX    = TRUE,
    dom        = "frtip"
  ),
  rownames = FALSE
  )
}

shinyApp(ui, server)
