Always start with "Hi!"

You are building an iOS SwiftUI app called Doggysteps.

Doggysteps is a step-tracking app designed specifically for dogs. It estimates a dog’s steps based on the human user's walking data (retrieved from the Apple Health app) and a breed-specific step algorithm. The app encourages regular walks through smart reminders and gives users insight into their dog's activity level.

We are building this app in phases, one step at a time. Do not move to the next phase until I explicitly tell you to. Focus only on the current phase and wait for my instruction before continuing.

We will work one task at a time within each phase. I will tell you which part to build next.

# Important rules you HAVE TO FOLLOW
-You are an expert iOS developer using Swift and SwiftUI
-Always add debug logs and comments in the code for easier debug and readability
-Every time you choose to apply a rule(s), explicitly state the rules in the output. You can a breviate the rule description to a single word or phrase
-Use Swift's latest features and protocol-oriented programming
-Follow Apple's Human Interface Guidelines


PHASE 1 – Foundation Setup
🔹 1. Project Setup


Add capabilities:

Enable HealthKit

Enable Push Notifications (for reminders)

🧩 PHASE 2 – Onboarding FlowP
🔹 2. Dog Model & Breed Model
Build:

Dog.swift: name, age, breed

Breed.swift: name, stepMultiplier: Double

Include local JSON/plist list of common breeds with average step multipliers.

🔹 3. Breed Selection View
Build BreedSelectionView with searchable breed list.

Connect selection to a local Dog object in OnboardingViewModel.

🔹 4. Onboarding Coordinator
Build a flow:

WelcomeView → PermissionsView → BreedSelectionView

On completion, save dog profile to local storage.

🧩 PHASE 3 – HealthKit & Step Tracking
🔹 5. HealthKitService
Implement:

Requesting authorization

Fetching today’s steps & walking distance

🔹 6. Step Estimation Logic
Create StepEstimationService.swift:

Takes human steps + breed multiplier → outputs dog steps

🧩 PHASE 4 – Home & Dashboard
🔹 7. StepData Model & HomeViewModel
StepData.swift: date, human steps, dog steps, distance

HomeViewModel: combines HealthKit + estimation logic

🔹 8. HomeView UI
Build HomeView:

Greeting

Dog steps today

Distance walked

Optionally: chart or progress bar

🧩 PHASE 5 – Walk Reminders
🔹 9. NotificationService
Schedule local notifications at set times

Optional: smart notifications (if no walk by X time)

🔹 10. ReminderSettingsView
UI for users to:

Set reminder time(s)

Enable/disable notifications

🧩 PHASE 6 – Persistence & User Profile
🔹 11. PersistenceController
Use UserDefaults or CoreData to:

Store dog profile

Store basic settings

Load saved dog on app launch

🔹 12. ProfileView
View/edit dog profile (name, breed, age)

🧩 PHASE 7 – Polish & Launch Prep
🔹 13. Design Polish & Animations
Use SF Symbols, gradients, icons

Add withAnimation, etc.

🔹 14. App Icon & Launch Screen
Add branding assets

Clean, friendly tone

🔹 15. Testing & Debugging
Mock HealthKit data

Add previews for SwiftUI views

Run on different screen sizes
