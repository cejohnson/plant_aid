defmodule PlantAidWeb.Router do
  use PlantAidWeb, :router

  import PlantAidWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PlantAidWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :put_user_token
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # scope "/", PlantAidWeb do
  #   pipe_through :browser

  #   get "/", PageController, :home
  # end

  # Other scopes may use custom stacks.
  # scope "/api", PlantAidWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:plant_aid, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      # live_dashboard "/dashboard", metrics: PlantAidWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", PlantAidWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [
        {PlantAidWeb.UserAuth, :redirect_if_user_is_authenticated}
      ] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
      live "/users/invite/:token", UserAcceptInviteLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", PlantAidWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/observations/:id/print", SampleController, :print
    get "/observations/export", ObservationController, :export_csv

    live_session :require_authenticated_user,
      on_mount: [
        {PlantAidWeb.UserAuth, :ensure_authenticated}
      ] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/locations", LocationLive.Index, :index
      live "/locations/new", LocationLive.Index, :new
      live "/locations/:id/edit", LocationLive.Index, :edit

      live "/locations/:id", LocationLive.Show, :show
      live "/locations/:id/show/edit", LocationLive.Show, :edit

      live "/alerts/settings", AlertSettingLive.Index, :index
      live "/alerts/settings/new", AlertSettingLive.Index, :new
      live "/alerts/settings/:id/edit", AlertSettingLive.Index, :edit

      live "/alerts/settings/:id", AlertSettingLive.Show, :show
      live "/alerts/settings/:id/show/edit", AlertSettingLive.Show, :edit

      live "/alerts", AlertLive.Index, :index
      live "/alerts/:id", AlertLive.Show, :show

      live "/observations", ObservationLive.Index, :index
      live "/observations/new", ObservationLive.Form, :new
      live "/observations/:id/edit", ObservationLive.Form, :edit
      live "/observations/:id", ObservationLive.Show, :show
      live "/observations/:id/submit-sample", ObservationLive.Show, :print

      live "/observations/:id/sample/new", ObservationLive.Show, :add_sample
      live "/observations/:id/sample/edit", ObservationLive.Show, :edit_sample
      # live "/samples/new", SampleLive.Index, :new
      # live "/samples/:id/edit", SampleLive.Index, :edit

      # live "/samples/:id", SampleLive.Show, :show
      # live "/samples/:id/show/edit", SampleLive.Show, :edit

      live "/test_results", DiagnosticTestResultLive.Index, :index
      live "/test_results/new", DiagnosticTestResultLive.Form, :new
      live "/test_results/:id/edit", DiagnosticTestResultLive.Form, :edit
      live "/test_results/:id", DiagnosticTestResultLive.Show, :show
      live "/test_results/:id/show/edit", DiagnosticTestResultLive.Form, :edit
    end
  end

  scope "/", PlantAidWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    get "/", PageController, :home
    get "/about", PageController, :about
    get "/funding", PageController, :funding
    get "/contact", PageController, :contact
    get "/publications", PageController, :publications
    get "/team", PageController, :team
    get "/pathogens", PageController, :pathogens
    get "/tools", PageController, :tools

    live_session :current_user,
      on_mount: [
        {PlantAidWeb.UserAuth, :mount_current_user}
      ] do
      live "/map", MapLive.Index, :index

      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/admin", PlantAidWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live_session :require_admin,
      on_mount: [
        {PlantAidWeb.UserAuth, :ensure_authenticated},
        {PlantAidWeb.UserAuth, :ensure_admin}
      ] do
      live "/", AdminLive, :index

      live "/users", UserLive.Index, :index
      live "/users/new", UserLive.Index, :new
      live "/users/:id/edit", UserLive.Index, :edit

      live "/users/:id", UserLive.Show, :show
      live "/users/:id/show/edit", UserLive.Show, :edit

      live "/location_types", LocationTypeLive.Index, :index
      live "/location_types/new", LocationTypeLive.Index, :new
      live "/location_types/:id/edit", LocationTypeLive.Index, :edit
      live "/location_types/:id", LocationTypeLive.Show, :show
      live "/location_types/:id/show/edit", LocationTypeLive.Show, :edit

      live "/hosts", HostLive.Index, :index
      live "/hosts/new", HostLive.Index, :new
      live "/hosts/:id/edit", HostLive.Index, :edit
      live "/hosts/:id", HostLive.Show, :show
      live "/hosts/:id/show/edit", HostLive.Show, :edit

      live "/pathologies", PathologyLive.Index, :index
      live "/pathologies/new", PathologyLive.Index, :new
      live "/pathologies/:id/edit", PathologyLive.Index, :edit
      live "/pathologies/:id", PathologyLive.Show, :show
      live "/pathologies/:id/show/edit", PathologyLive.Show, :edit

      live "/diagnostic_methods", DiagnosticMethodLive.Index, :index
      live "/diagnostic_methods/new", DiagnosticMethodLive.Index, :new
      live "/diagnostic_methods/:id/edit", DiagnosticMethodLive.Index, :edit

      live "/diagnostic_methods/:id", DiagnosticMethodLive.Show, :show
      live "/diagnostic_methods/:id/show/edit", DiagnosticMethodLive.Show, :edit
    end
  end

  scope "/superuser", PlantAidWeb do
    import Phoenix.LiveDashboard.Router

    pipe_through [:browser, :require_authenticated_user, :require_superuser]

    live_dashboard "/dashboard", metrics: PlantAidWeb.Telemetry
  end
end
