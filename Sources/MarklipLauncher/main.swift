import Cocoa

// Create the application
let app = NSApplication.shared

// Create and set the delegate
let delegate = AppDelegate()
app.delegate = delegate

// Set activation policy to accessory to prevent Dock icon
app.setActivationPolicy(.accessory)

// Run the application
app.run()
