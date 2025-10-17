 MovieManiac
 
 MovieManiac is a Flutter-based movie browsing app that allows users to:
 • Sign in / register with Firebase Authentication
 • Discover movies by genre using TMDb API
 • View movie details, ratings, and trailers
 • Contact the developers via the built-in Contact Us page
 Features
 • Firebase Integration (Auth, Core, .env for keys)
 • Movie Database (browse by genre, ratings, trailers)
 • UI (modern design, splash screen, custom fonts)
 • Contact Page (form + additional contact details)
 
 
 Tech Stack
 • Flutter (Dart)
 • Firebase (Auth, Core)
 • TMDb API
 • flutter_dotenv
 Project Structure
 • main.dart - Entry point
 • firebase_options.dart - Firebase config
 • SplashScreen.dart - Splash screen
 • GenreMoviesPage.dart - Movies by genre
 • TrailerPage.dart - Trailers
 • ContactUsPage.dart - Contact form
 • assets/.env - Environment variables

 
 Environment Setup
• All sensitive API keys are stored inside assets/.env
 • Update pubspec.yaml to include:
 • assets/: for images and banners
 • assets/.env: for environment variables
 Getting Started
 • Clone repo: git clone https://github.com/yourusername/movie_maniac.git
 • Install deps: flutter pub get
 • Configure Firebase: flutterfire configure
 • Run app: flutter run -d android / ios / chrome

 
 Notes
 • Restrict Firebase API keys
 • Use TMDb API key for read-only requests
 • Never commit .env to public repos
 
