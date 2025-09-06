# CoachMaster Flutter + Firebase Rebuild - Product Requirements Document

## 1. Executive Summary

### Project Overview
Rebuilding CoachMaster from React/Express/PostgreSQL to Flutter + Firebase to create a modern, scalable, cross-platform sports team management application with enhanced real-time capabilities and offline-first architecture.

### Key Objectives
- **Cross-platform**: Single codebase for iOS, Android, and web
- **Real-time**: Instant updates across all devices
- **Offline-first**: Full functionality without internet connection
- **Scalable**: Firebase infrastructure for automatic scaling
- **Modern UX**: Material Design 3 with Flutter's advanced animations
- **Cost-effective**: Reduce backend maintenance overhead

## 2. Current System Analysis

### Existing Features (from React/PostgreSQL version)
Based on the current codebase analysis:

#### Core Entities
- **Seasons**: July-June format sports seasons
- **Teams**: Multiple teams per season
- **Players**: Individual player profiles with statistics
- **Trainings**: Training session management
- **Matches**: Match scheduling and results
- **Statistics**: Comprehensive player and team statistics

#### Key Functionalities
- Player management (CRUD operations)
- Training session creation and attendance tracking
- Match scheduling and convocation system
- Individual match statistics per player
- Photo upload for player profiles
- CSV export functionality
- Team and season management

#### Technical Limitations
- Web-only application
- PostgreSQL maintenance overhead
- No real-time updates
- Limited offline capabilities
- Server-side rendering dependencies

## 3. Flutter + Firebase Architecture

### Technology Stack

#### Frontend
- **Framework**: Flutter 3.x (latest stable)
- **Language**: Dart 3.x
- **State Management**: Riverpod 2.x
- **Navigation**: GoRouter
- **UI Framework**: Material Design 3
- **Local Storage**: Hive + drift (SQLite)
- **Animations**: Flutter's built-in animation system

#### Backend & Infrastructure
- **Database**: Cloud Firestore
- **Authentication**: Firebase Auth (email, Google, Apple)
- **Storage**: Firebase Cloud Storage
- **Functions**: Cloud Functions for complex operations
- **Analytics**: Google Analytics for Firebase
- **Crash Reporting**: Crashlytics
- **Performance**: Firebase Performance Monitoring

#### Development Tools
- **IDE**: VS Code / Android Studio
- **Testing**: Flutter Test + Mockito
- **CI/CD**: GitHub Actions + Firebase Hosting
- **Code Quality**: Dart analysis + custom lint rules

### Architecture Patterns
- **Clean Architecture**: Domain-driven design
- **Repository Pattern**: Abstract data layer
- **BLoC Pattern**: Business logic components
- **Dependency Injection**: GetIt + injectable
- **Offline-First**: Local cache with sync

## 4. Core Feature Requirements

### 4.1 User Management
#### Authentication
- Email/password authentication
- Google Sign-In integration
- Apple Sign-In (iOS)
- Guest mode with data sync
- Multi-device synchronization

#### User Roles
- **Coach**: Full team management access
- **Assistant Coach**: Limited management capabilities
- **Player**: View own statistics and team info
- **Parent**: View child's information (read-only)

### 4.2 Team & Season Management
#### Season Management
- Create sports seasons (July-June format)
- Archive old seasons
- Season statistics overview
- Multi-season team continuity

#### Team Management
- Create multiple teams per season
- Team roster management
- Team statistics aggregation
- Team photo and branding

### 4.3 Player Management
#### Player Profiles
- Comprehensive player information
- Photo upload and management
- Position tracking
- Preferred foot
- Birth date and age calculation
- Medical information (optional)

#### Player Statistics
- Career statistics across seasons
- Season-by-season breakdown
- Per-match detailed statistics
- Training attendance tracking
- Performance trends and graphs

### 4.4 Training Management
#### Session Creation
- Schedule training sessions
- Set training objectives
- Location management
- Duration tracking

#### Attendance Tracking
- Mark player attendance/absence
- Reason for absence
- Historical attendance reports
- Automatic reminders

### 4.5 Match Management
#### Match Scheduling
- Schedule matches against opponents
- Home/away designation
- Match objectives and tactics
- Convocation system

#### Match Statistics
- Real-time match tracking
- Individual player statistics
- Goals, assists, cards
- Minutes played
- Player ratings
- Match outcome recording

### 4.6 Advanced Features
#### Real-time Updates
- Live match commentary
- Real-time statistics updates
- Push notifications for events
- Team communication features

#### Data Analysis
- Performance trends
- Comparative analysis
- Predictive insights
- Custom report generation

#### Export & Sharing
- PDF report generation
- CSV data export
- Share statistics via social media
- Print-friendly formats

## 5. Firebase Data Structure

### 5.1 Firestore Collections

#### Users Collection
```
collection: users
- userId (string)
- email (string)
- displayName (string)
- role (enum: coach, assistant, player, parent)
- createdAt (timestamp)
- updatedAt (timestamp)
- avatarUrl (string)
- preferences (map)
```

#### Seasons Collection
```
collection: seasons
- seasonId (string)
- name (string)
- startDate (timestamp)
- endDate (timestamp)
- status (enum: active, archived)
- createdAt (timestamp)
- createdBy (string) // userId
```

#### Teams Collection
```
collection: teams
- teamId (string)
- seasonId (string) // reference
- name (string)
- description (string)
- logoUrl (string)
- coachId (string) // reference to users
- assistantCoachIds (array<string>)
- createdAt (timestamp)
- updatedAt (timestamp)
```

#### Players Collection
```
collection: players
- playerId (string)
- teamId (string) // reference
- userId (string) // optional, for linked accounts
- firstName (string)
- lastName (string)
- position (string)
- preferredFoot (string)
- birthDate (timestamp)
- photoUrl (string)
- medicalInfo (map)
- emergencyContact (map)
- createdAt (timestamp)
- updatedAt (timestamp)
```

#### Trainings Collection
```
collection: trainings
- trainingId (string)
- teamId (string)
- date (timestamp)
- startTime (timestamp)
- endTime (timestamp)
- location (string)
- objectives (array<string>)
- coachNotes (string)
- createdAt (timestamp)
- updatedAt (timestamp)
```

#### TrainingAttendances Collection
```
collection: trainingAttendances
- attendanceId (string)
- trainingId (string)
- playerId (string)
- status (enum: present, absent, late)
- reason (string)
- arrivalTime (timestamp)
- createdAt (timestamp)
```

#### Matches Collection
```
collection: matches
- matchId (string)
- teamId (string)
- seasonId (string)
- opponent (string)
- date (timestamp)
- location (string)
- isHome (boolean)
- goalsFor (number)
- goalsAgainst (number)
- result (enum: win, loss, draw)
- status (enum: scheduled, live, completed)
- tactics (map)
- createdAt (timestamp)
- updatedAt (timestamp)
```

#### MatchConvocations Collection
```
collection: matchConvocations
- convocationId (string)
- matchId (string)
- playerId (string)
- status (enum: convoked, playing, substitute, notPlaying)
- createdAt (timestamp)
```

#### MatchStatistics Collection
```
collection: matchStatistics
- statId (string)
- matchId (string)
- playerId (string)
- goals (number)
- assists (number)
- yellowCards (number)
- redCards (number)
- minutesPlayed (number)
- rating (number)
- position (string)
- notes (string)
- createdAt (timestamp)
- updatedAt (timestamp)
```

### 5.2 Cloud Storage Structure

```
bucket: coachmaster-files
├── team-logos/
│   └── {teamId}.jpg
├── player-photos/
│   └── {playerId}.jpg
├── match-photos/
│   └── {matchId}/
├── training-photos/
│   └── {trainingId}/
└── reports/
    └── {reportType}_{timestamp}.pdf
```

### 5.3 Security Rules

#### Firestore Security Rules
```javascript
// Users can only read/write their own user document
match /users/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if request.auth != null && request.auth.uid == userId;
}

// Coaches can manage their teams
match /teams/{teamId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && 
    request.auth.uid in resource.data.coachIds;
}

// Players can only access their own data
match /players/{playerId} {
  allow read: if request.auth != null && 
    (request.auth.uid == resource.data.userId || 
     isTeamMember(request.auth.uid, resource.data.teamId));
  allow write: if request.auth != null && 
    isTeamCoach(request.auth.uid, resource.data.teamId);
}
```

## 6. Flutter UI/UX Specifications

### 6.1 Design System
- **Primary Color**: Deep Orange (#FF5722)
- **Secondary Color**: Blue Grey (#607D8B)
- **Typography**: Material Design type scale
- **Icons**: Material Icons + custom sports icons
- **Spacing**: 8dp grid system
- **Elevation**: Material Design 3 shadows

### 6.2 Screen Architecture

#### Authentication Flow
- **Welcome Screen**: Logo, app description, login/signup options
- **Login Screen**: Email/password, social login buttons
- **Register Screen**: Coach/player registration
- **Forgot Password**: Email reset flow

#### Main App Structure
**Bottom Navigation (5 tabs):**
1. **Dashboard** (Home icon)
   - Team overview
   - Recent activities
   - Quick actions

2. **Players** (People icon)
   - Player list
   - Player profiles
   - Statistics
   - Add/edit players

3. **Trainings** (Calendar icon)
   - Training schedule
   - Attendance tracking
   - Training details

4. **Matches** (Sports icon)
   - Match schedule
   - Live matches
   - Match statistics

5. **Settings** (Settings icon)
   - Profile management
   - Team settings
   - App preferences

### 6.3 Key Screens

#### Dashboard Screen
- **Team Summary Card**: Current season stats
- **Recent Trainings**: Last 3 trainings with attendance
- **Upcoming Matches**: Next 3 matches
- **Quick Actions**: Add player, schedule training, create match

#### Player Profile Screen
- **Header**: Player photo, name, position
- **Statistics Cards**: Career stats, season stats
- **Performance Chart**: Goals/assists over time
- **Training Attendance**: Visual attendance tracker
- **Match History**: Recent matches with ratings

#### Training Details Screen
- **Training Info**: Date, time, location, objectives
- **Attendance List**: All players with status
- **Notes Section**: Coach notes and observations
- **Photo Gallery**: Training session photos

#### Match Live Screen
- **Score Board**: Real-time score updates
- **Player List**: Convocated players with live stats
- **Event Timeline**: Goals, cards, substitutions
- **Live Commentary**: Real-time match updates

### 6.4 Responsive Design
- **Mobile**: Single column layout
- **Tablet**: Two-column layout for lists and details
- **Web**: Three-column layout with navigation sidebar
- **Foldable Devices**: Adaptive layouts for different screen sizes

## 7. Development Phases & Milestones

### Phase 1: Foundation (Weeks 1-4)
**Goal**: Basic app structure and authentication
- [ ] Flutter project setup with Firebase integration
- [ ] Authentication system (email, Google, Apple)
- [ ] Basic navigation structure
- [ ] User profile management
- [ ] Firebase configuration and security rules

**Deliverables**: Working authentication flow, basic app structure

### Phase 2: Core Entities (Weeks 5-8)
**Goal**: Season, team, and player management
- [ ] Season CRUD operations
- [ ] Team management and roster
- [ ] Player profiles and photos
- [ ] Basic statistics display
- [ ] Offline storage implementation

**Deliverables**: Full player management system

### Phase 3: Training Management (Weeks 9-12)
**Goal**: Training sessions and attendance
- [ ] Training schedule creation
- [ ] Attendance tracking system
- [ ] Training notes and objectives
- [ ] Photo upload for trainings
- [ ] Attendance reports

**Deliverables**: Complete training management system

### Phase 4: Match Management (Weeks 13-16)
**Goal**: Match scheduling and statistics
- [ ] Match creation and scheduling
- [ ] Convocation system
- [ ] Match statistics entry
- [ ] Real-time match updates
- [ ] Match result recording

**Deliverables**: Full match management with statistics

### Phase 5: Advanced Features (Weeks 17-20)
**Goal**: Analytics and advanced functionality
- [ ] Performance analytics dashboard
- [ ] Advanced statistics and trends
- [ ] PDF report generation
- [ ] Push notifications
- [ ] Data export functionality

**Deliverables**: Analytics dashboard and reporting system

### Phase 6: Polish & Launch (Weeks 21-24)
**Goal**: Production readiness and launch
- [ ] Performance optimization
- [ ] Security audit
- [ ] App store preparation
- [ ] Beta testing
- [ ] Documentation and training materials

**Deliverables**: Production-ready app with documentation

## 8. Technical Specifications

### 8.1 Performance Requirements
- **App Launch**: < 2 seconds cold start
- **Screen Transitions**: < 300ms
- **API Response**: < 500ms for standard queries
- **Offline Sync**: < 5 seconds for data sync
- **Image Loading**: Progressive loading with placeholders

### 8.2 Offline Capabilities
- **Full CRUD operations** when offline
- **Conflict resolution** for concurrent edits
- **Background sync** when connection restored
- **Optimistic updates** for better UX
- **Data compression** for reduced storage

### 8.3 Security Requirements
- **End-to-end encryption** for sensitive data
- **Role-based access control**
- **Data validation** on client and server
- **Secure file uploads** with virus scanning
- **GDPR compliance** for data privacy

### 8.4 Scalability Considerations
- **Firestore indexing** for query performance
- **Pagination** for large datasets
- **Lazy loading** for images and data
- **Caching strategies** for frequently accessed data
- **CDN integration** for global performance

## 9. Testing Strategy

### 9.1 Testing Levels
- **Unit Tests**: Business logic and data models
- **Widget Tests**: UI components and interactions
- **Integration Tests**: Firebase integration
- **End-to-End Tests**: Complete user workflows
- **Performance Tests**: Load testing and optimization

### 9.2 Test Coverage Targets
- **Unit Tests**: 90% coverage
- **Widget Tests**: 85% coverage
- **Integration Tests**: 80% coverage
- **E2E Tests**: All critical user paths

### 9.3 Testing Tools
- **Flutter Test**: Unit and widget testing
- **Firebase Test Lab**: Device testing
- **Mockito**: Mocking and stubbing
- **Golden Tests**: UI regression testing

## 10. Deployment & Distribution

### 10.1 App Stores
- **Google Play Store**: Android deployment
- **Apple App Store**: iOS deployment
- **Progressive Web App**: Web deployment via Firebase Hosting

### 10.2 Release Strategy
- **Internal Testing**: 2 weeks with core team
- **Closed Beta**: 4 weeks with selected users
- **Open Beta**: 4 weeks public testing
- **Production Release**: Gradual rollout

### 10.3 Monitoring & Analytics
- **Crashlytics**: Crash reporting and analysis
- **Performance Monitoring**: App performance metrics
- **Google Analytics**: User behavior tracking
- **Custom Events**: Feature usage tracking

## 11. Success Metrics

### 11.1 User Engagement
- **Daily Active Users**: Target 100+ within 3 months
- **Session Duration**: Average 15+ minutes
- **Feature Adoption**: 80% of users use core features
- **User Retention**: 70% retention after 30 days

### 11.2 Performance Metrics
- **App Rating**: 4.5+ stars on app stores
- **Crash Rate**: < 0.5% of sessions
- **Load Time**: < 2 seconds for all screens
- **Offline Sync Success**: 99.9% success rate

### 11.3 Business Metrics
- **User Growth**: 50% month-over-month growth
- **Team Creation**: 10+ teams created daily
- **Data Usage**: 1000+ daily active teams
- **Revenue**: In-app purchases for premium features

## 12. Risk Assessment & Mitigation

### 12.1 Technical Risks
- **Firebase Limits**: Implement data sharding and optimization
- **Offline Sync Complexity**: Comprehensive testing and conflict resolution
- **Performance Issues**: Continuous monitoring and optimization
- **Security Vulnerabilities**: Regular security audits

### 12.2 Business Risks
- **User Adoption**: Gradual migration with data import tools
- **Feature Parity**: Detailed feature mapping and validation
- **Cost Overruns**: Phased development with regular reviews
- **Competition**: Focus on unique features and user experience

## 13. Future Enhancements

### 13.1 Phase 2 Features
- **Video Analysis**: Training session recording and analysis
- **AI Insights**: Machine learning for performance predictions
- **Social Features**: Team communication and sharing
- **Multi-language Support**: Internationalization
- **Wearable Integration**: Fitness tracker connectivity

### 13.2 Advanced Analytics
- **Predictive Analytics**: Injury risk assessment
- **Team Performance**: Advanced team metrics
- **Scouting Integration**: Player recruitment tools
- **Tournament Management**: Multi-team tournament support

## 14. Budget & Resources

### 14.1 Development Team
- **Flutter Developer**: 1 senior developer (full-time)
- **Firebase Engineer**: 1 part-time for backend setup
- **UI/UX Designer**: 1 part-time for design system
- **QA Engineer**: 1 part-time for testing

### 14.2 Infrastructure Costs
- **Firebase**: Estimated $50-200/month based on usage
- **Development Tools**: $100/month for CI/CD and testing
- **App Store Fees**: $25 Google Play + $99 Apple Developer

### 14.3 Timeline & Budget
- **Total Duration**: 24 weeks
- **Development Cost**: $40,000 - $60,000
- **Infrastructure**: $1,000 - $2,000 annually
- **Maintenance**: 20% of development cost annually

## 15. Conclusion

This PRD outlines a comprehensive plan for rebuilding CoachMaster using Flutter and Firebase. The new architecture will provide superior user experience, cross-platform compatibility, and scalable infrastructure while maintaining all existing functionality and adding significant enhancements.

The phased approach ensures gradual delivery of features with continuous user feedback, while the modern tech stack provides a solid foundation for future growth and feature expansion.

The project is designed to be completed within 24 weeks with a clear roadmap, measurable milestones, and defined success criteria. The Flutter + Firebase combination offers the best balance of development speed, user experience, and long-term maintainability for CoachMaster's continued success.