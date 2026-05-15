## English Summary

Stockly is an inventory and stock management application developed as a Final Degree Project (TFG) for the Multiplatform Application Development degree (DAM).

The application is focused on small hospitality and restaurant businesses, allowing users to manage products, recipes, sales, stock movements, waste control and supplier orders from a single system.

Stockly follows an offline-first architecture.  
The application can continue working without internet connection by storing operations locally in SQLite and synchronizing them later when the backend becomes available again.

### Main Features

- Product management
- Recipe and ingredient management
- Sales registration
- Waste registration
- Stock entry and replenishment
- Barcode scanner integration
- Supplier orders
- Offline synchronization
- Conflict detection
- Login offline support
- UUID idempotency system

### Technologies Used

#### Frontend
- Flutter
- Dart
- SQLite
- Provider
- Supabase Auth

#### Backend
- Java 17
- Spring Boot
- Spring Security
- Spring Data JPA
- REST API

#### Database
- PostgreSQL
- Supabase

### Future Improvements

- Advanced dashboard and analytics
- Full offline history support
- Advanced stock movement details
- Periodic automatic synchronization
- Advanced conflict management
- Real offline support for Web/PWA
- Cost and profit analytics
- Recipe waste management