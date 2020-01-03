shinyuser
================

> Alpha version 0.0.0.1 (under active development)

This is a demonstration of how to implement user authentication directly
in a shiny app. The core idea is to provide a simple, secure and
modularized solution.

Features:

1.  user’s data is saved as JSON file in `data/users`
2.  R6 class user management
3.  admin panel to edit user data
4.  easy to integrate with `shiny.info`

Minimal Example of
`shinyuser`

``` r
pacman::p_load(devtools, shiny, shiny.semantic, semantic.dashboard, tidyverse,
                RSQLite, dbplyr, shinyjs, R6)

ui <- dashboardPage(
  dashboardHeader(
    inverted = T,
    manager_ui("manager")
  ),
  dashboardSidebar(
    side = "left", size = "", inverted = T,
    sidebarMenu(
      div(class = "item",
          h4(class = "ui inverted header", "Something")
      )
    )
  ),
  dashboardBody(
    div(class = "sixteen wide column",
      "Something great content"
    )
  )
)

server <- function(input, output) {
  
  ### User Authentification
  user <- callModule(login_server, "user")
  ### User Managment
  callModule(manager_server, "manager", user)
  
  output$main <- renderUI({
    if(user()$status == 1){
      ui
    }
  })
  
  observe({ glimpse(user()) })

  ### Your Code

}
```

The app will start up with a login/sign in modal.

<img src = "demo.gif"> <!-- width = "80%" -->
