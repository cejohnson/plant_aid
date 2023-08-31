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

    live_session :require_authenticated_user,
      on_mount: [
        {PlantAidWeb.UserAuth, :ensure_authenticated},
        {PlantAid.ConnectionMonitor, :monitor_connection}
      ] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/observations", ObservationLive.Index, :index
      live "/observations/new", ObservationLive.Form, :new
      live "/observations/:id/edit", ObservationLive.Form, :edit
      live "/observations/:id", ObservationLive.Show, :show
      live "/observations/:id/submit-sample", ObservationLive.Show, :print
    end
  end

  scope "/", PlantAidWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [
        {PlantAidWeb.UserAuth, :mount_current_user},
        {PlantAid.ConnectionMonitor, :monitor_connection}
      ] do
      live "/", HomeLive.Index, :index

      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/admin", PlantAidWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live_session :require_admin,
      on_mount: [
        {PlantAidWeb.UserAuth, :ensure_authenticated},
        {PlantAid.ConnectionMonitor, :monitor_connection}
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
    end
  end

  scope "/admin", PlantAidWeb do
    import Phoenix.LiveDashboard.Router

    pipe_through [:browser, :require_authenticated_user, :require_superuser]

    live_dashboard "/dashboard", metrics: PlantAidWeb.Telemetry
  end
end
