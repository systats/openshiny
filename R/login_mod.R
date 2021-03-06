#' form_login
#' @export 
form_login <- function(id){
  ns <- NS(id)
  div(class = "ui form",
    div(class = "field",
      div(class = "ui left icon input", id = ns("frame_user"),
        HTML('<i class="ui user icon"></i>'),
        shiny::tags$input(id = ns("name"), type = "text", value = "" , placeholder = "Username")
      )
    ),
    div(class = "field",
      div(class = "ui left icon input", id = ns("frame_pw"),
        HTML('<i class="ui key icon"></i>'),
        shiny::tags$input(id = ns("pw"), type = "password", value = "" , placeholder = "Password")
      )
    ),
    div(class = "ui fluid button action-button", id = ns("login"), HTML('<i class="ui unlock alternate icon"></i>'))
  )
}

#' form_signin
#' @export 
form_signin <- function(id){
  ns <- NS(id)
  div(class = "ui form",
    div(class = "field",
      div(class = "ui left icon input",
        HTML('<i class="ui user icon"></i>'),
        shiny::tags$input(id = ns("user"), type = "text", value="" , placeholder="name")
      )
    ),
    div(class = "field",
      div(class = "ui left icon input",
        HTML('<i class="ui key icon"></i>'),
        shiny::tags$input(id = ns("pw1"), type = "password", value = "" , placeholder = "Secret")
      )
    ),
    div(class = "field",
      div(class = "ui left icon input",
        HTML('<i class="ui key icon"></i>'),
        shiny::tags$input(id = ns("pw2"), type = "password", value = "" , placeholder = "Secret")
      )
    ),
    div(class = "ui fluid button action-button", id = ns("signin"), HTML('<i class="ui sign in icon"></i>'))
  )
}

#' form_recover
#' @export 
form_recover <- function(id){
  ns <- NS(id)
  div(class = "ui form",
    div(class = "field",
      label("Send an email to get new creds"),
      div(class="ui left icon input",
        HTML('<i class="ui envelop icon"></i>'),
        shiny::tags$input(id = ns("email"), type = "text", value = "" , placeholder = "name")
      )
    ),
    div(class = "ui fluid button action-button", id = ns("recover"), HTML('<i class="ui undo alternate icon"></i>'))
  )
}

#' clickjs
#' @export 
clickjs <- '$(document).keyup(function(event) {
    if (event.key == "Enter") {
        $("#user-login").click();
    }
});'

#' login_ui
#' @export 
login_ui <- function(id, head = NULL){
  
  ns <- NS(id)
  
  tagList(
    tags$head(
      tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js") 
    ),
    shinyjs::useShinyjs(),
    extendShinyjs(text = jsCode, functions = c("getcookie","setcookie","rmcookie")),
    div(class = "ui inverted active page dimmer", id = ns("buffer"),
      style = "background-color:#e0e1e2;",
      div(class="ui text loader", "Loading Data")
    ),
    hidden(
      div(class = "ui inverted active page dimmer", id = ns("checkin"), 
        style = "background-color:#e0e1e2;",
        div(class = "ui card", align = "left", #style = "margin-top: 10%;",
          div(class = "content",
            head,
            div(class="ui accordion", id = "checkin_options",
              div(class = "active title", id = "default_title",
                HTML('<i class="ui dropdown icon"></i>'),
                "Login"
              ),
              div(class="active content", id = "default_content",
                form_login(id)
              )
            )
          )
        )
      )
    ),
    shiny::tags$script("$('.ui.accordion').accordion();"),
    # https://stackoverflow.com/questions/32335951/using-enter-key-with-action-button-in-r-shiny
    shiny::tags$script(clickjs)
  )
}

#' check_credentials
#' @export 
check_credentials <- function(users, .user, .pw){
  
  trial <- dplyr::filter(users, name == .user & pw == .pw)
  
  if(nrow(trial) == 1) {
    session <- dplyr::mutate(trial, status = 1)
  } else {
    session <- NULL
  }
  return(session)
}

# https://gist.github.com/calligross/e779281b500eb93ee9e42e4d72448189
#' jsCode
#' @export 
jsCode <- '
  shinyjs.getcookie = function(params) {
    var cookie = Cookies.get("id");
    if (typeof cookie !== "undefined") {
      Shiny.onInputChange("user-jscookie", cookie);
    } else {
      var cookie = "";
      Shiny.onInputChange("user-jscookie", cookie);
    }
  }
  shinyjs.setcookie = function(params) {
    Cookies.set("id", escape(params), { expires: 0.5 });  
    Shiny.onInputChange("user-jscookie", params);
  }
  shinyjs.rmcookie = function(params) {
    Cookies.remove("id");
    Shiny.onInputChange("user-jscookie", "");
  }
'

#' login_server
#' @export
login_server <- function(input, output, session, users){
  
  status <- reactiveVal("")
   
  observe({
    req(users())
    shinyjs::js$getcookie()
    
    if(is.null(input$jscookie)) return(NULL)
    
    known <- dplyr::mutate(dplyr::filter(users(), name == input$jscookie), status = 1)
    
    if(nrow(known) > 0) {
      if(isolate(status()) == known$name[1]){
        cat(".")
        #print(glue::glue("No change for cookie {status()}"))
      } else {
        print(glue::glue("Found valid cookie: {input$jscookie}"))
        status(input$jscookie)
      }
      shinyjs::hide("checkin")
      shinyjs::hide("buffer")
    } else {
      
      print(glue::glue("No valid cookie found"))
      status('')
      shinyjs::show("checkin")
      print(glue::glue("Show Login Panel"))
      
    }
  })
  
  observeEvent(input$login, {
    
    print(glue::glue("Checking Credentials"))
    known <- check_credentials(users(), input$name, input$pw)
    
    if(!is.null(known)){
      if(known$status == 1){
        print(glue::glue("Successfully logged in"))
        status(known$name[1])
        shinyjs::js$setcookie(known$name[1])
      }
    } else {
      print(glue::glue("Some input error"))
      shinyjs::runjs("$('#user-checkin').transition('shake');")
      status('')
    }
  })
  
  observeEvent( input$logout ,{
    # reset session cookies
    print(glue::glue("Logged out"))
    status('')
    shinyjs::js$rmcookie()
    # shinyjs::runjs("history.go(0);")
    # shinyjs::runjs("$('.dimmer').dimmer('show');")
  })
  
  out <- reactive({
    req(status())
    # only return data if valid login otherwise NULL
    if(status() != "") {
      print(glue::glue("Return user data"))
      return(users() %>% filter(name == status()))
    } else {
      print(glue::glue("Stop process"))
      return(NULL)
    }
  })

  return(out)
}
