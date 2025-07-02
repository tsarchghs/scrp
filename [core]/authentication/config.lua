Config = {}

Config.Security = {
    PasswordMinLength = 6,
    RequireStrongPassword = true, -- Requires uppercase, lowercase, number, and special character
    MaxLoginAttempts = 5,
    LockoutDuration = 300, -- 5 minutes in seconds
    SessionTimeout = 3600, -- 1 hour in seconds
    IPBanAfterFailedAttempts = 10 -- Ban IP after 10 failed attempts
}

Config.Messages = {
    LoginPrompt = "Welcome to the server! Please log in or register.",
    LoginHelp = "Use /login [username] [password] or /register [username] [password]",
    LoggedIn = "You are already logged in.",
    LoginSuccess = "Successfully logged in! Welcome back, %s.",
    LoginFailed = "Invalid username or password.",
    RegisterSuccess = "Account registered successfully! You can now log in.",
    RegisterFailed = "Failed to create account. Please try again.",
    UsernameExists = "Username already exists.",
    PasswordTooShort = "Password must be at least %d characters long.",
    PasswordNotStrong = "Password must contain an uppercase letter, a lowercase letter, a number, and a special character.",
    TooManyAttempts = "Too many failed login attempts. Please try again in %d seconds.",
    IPBanned = "Your IP address has been temporarily banned due to too many failed login attempts."
}

-- Style for the help text
Config.HelpTextStyle = {
    backgroundColor = "rgba(0, 0, 0, 0.7)",
    color = "white",
    padding = "15px",
    borderRadius = "5px",
    fontFamily = "Arial, sans-serif",
    fontSize = "16px",
    textAlign = "center",
    position = "fixed",
    top = "30%",
    left = "50%",
    transform = "translate(-50%, -50%)",
    zIndex = "1000"
}