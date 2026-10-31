import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildBrandHeader(),
            const SizedBox(height: 16),

            // Introduction
            _buildParagraph(
              'This Privacy Policy explains how MessKhojo (“MessKhojo”, “we”, “us”, or “our”) collects, uses, stores, discloses, and protects information when you use the MessKhojo mobile application (“App”), website, and related services (collectively, the “Services”).',
            ),
            _buildParagraph(
              'MessKhojo is an online platform that helps users discover accommodation options such as messes, hostels and PGs and connect with the relevant property owners or managers.',
            ),
            _buildParagraph(
              'MessKhojo generally acts as an intermediary/discovery platform. We do not own, operate, manage, or control the properties listed on the platform unless expressly stated otherwise.',
            ),
            _buildParagraph(
              'By using the App, you acknowledge that you have read and understood this Privacy Policy.',
            ),
            _buildNoticeBox(
              'If you do not agree with this Privacy Policy, please do not use the Services.',
            ),
            const SizedBox(height: 16),
            _buildDivider(),

            // 1. INFORMATION WE COLLECT
            _buildSectionHeader('1. INFORMATION WE COLLECT'),
            _buildParagraph(
              'The information we collect depends on how you use MessKhojo and the features you choose to access.',
            ),
            _buildSubHeader('1.1 Information You Provide Directly'),
            _buildParagraph('Depending on the features available to you, we may collect:'),
            _buildBulletPoint('Name'),
            _buildBulletPoint('Mobile/telephone number'),
            _buildBulletPoint('Email address'),
            _buildBulletPoint('Account/login information'),
            _buildBulletPoint('Password or authentication information, where applicable'),
            _buildBulletPoint('City, locality or accommodation preferences'),
            _buildBulletPoint('Contact preferences'),
            _buildBulletPoint('Information provided during booking or enquiry requests'),
            _buildBulletPoint('Information submitted through customer support'),
            _buildBulletPoint('Feedback, reviews and ratings'),
            _buildBulletPoint('Photographs or other content that you voluntarily upload'),
            _buildBulletPoint('Information provided when reporting or claiming a listing'),
            _buildBulletPoint('Information required to communicate with property owners/managers'),
            _buildParagraph('We ask you to provide accurate and current information.'),
            _buildDivider(),

            // 2. INFORMATION RELATED TO ACCOMMODATION SEARCHES
            _buildSectionHeader('2. INFORMATION RELATED TO ACCOMMODATION SEARCHES'),
            _buildParagraph(
              'When you search for or interact with accommodation listings, we may process information such as:',
            ),
            _buildBulletPoint('Search queries'),
            _buildBulletPoint('Selected city/locality'),
            _buildBulletPoint('Budget preferences'),
            _buildBulletPoint('Accommodation preferences'),
            _buildBulletPoint('Filters and preferences'),
            _buildBulletPoint('Listings viewed'),
            _buildBulletPoint('Enquiries or booking requests'),
            _buildBulletPoint('Interactions with property listings'),
            _buildParagraph(
              'We use this information to provide and improve the accommodation discovery experience.',
            ),
            _buildDivider(),

            // 3. LOCATION INFORMATION
            _buildSectionHeader('3. LOCATION INFORMATION'),
            _buildParagraph(
              'MessKhojo may request access to your device location where location functionality is necessary for features such as:',
            ),
            _buildBulletPoint('Finding accommodation near your location'),
            _buildBulletPoint('Showing relevant locations'),
            _buildBulletPoint('Improving location-based search results'),
            _buildBulletPoint('Providing map-related functionality'),
            _buildParagraph(
              'Depending on the feature and your device settings, location information may be precise or approximate.',
            ),
            _buildParagraph(
              'You can control location permissions through your Android device settings. If you deny location permission, certain location-based features may not work or may provide reduced functionality.',
            ),
            _buildParagraph(
              'We will not request location access merely for unrelated purposes. Google Play requires sensitive permissions to be necessary for the app’s current functionality and appropriately disclosed.',
            ),
            _buildDivider(),

            // 4. DEVICE AND TECHNICAL INFORMATION
            _buildSectionHeader('4. DEVICE AND TECHNICAL INFORMATION'),
            _buildParagraph(
              'When you use the App, certain technical information may be collected automatically, such as:',
            ),
            _buildBulletPoint('IP address'),
            _buildBulletPoint('Device type'),
            _buildBulletPoint('Device model'),
            _buildBulletPoint('Operating system and version'),
            _buildBulletPoint('App version'),
            _buildBulletPoint('Language and regional settings'),
            _buildBulletPoint('Network information'),
            _buildBulletPoint('General device configuration'),
            _buildBulletPoint('Crash and diagnostic information'),
            _buildBulletPoint('App performance information'),
            _buildBulletPoint('Log information'),
            _buildBulletPoint('Date and time of interactions'),
            _buildBulletPoint('Features accessed and usage information'),
            _buildParagraph('We use this information primarily to:'),
            _buildBulletPoint('Operate the App'),
            _buildBulletPoint('Maintain security'),
            _buildBulletPoint('Detect errors'),
            _buildBulletPoint('Diagnose technical problems'),
            _buildBulletPoint('Improve performance'),
            _buildBulletPoint('Prevent fraud and abuse'),
            _buildBulletPoint('Understand general usage patterns'),
            _buildParagraph(
              'We do not intentionally collect persistent device identifiers such as IMEI or IMSI for purposes prohibited by Google Play policy. Google Play specifically restricts linking persistent device identifiers with personal or sensitive information.',
            ),
            _buildDivider(),

            // 5. PHOTOS, IMAGES AND USER-GENERATED CONTENT
            _buildSectionHeader('5. PHOTOS, IMAGES AND USER-GENERATED CONTENT'),
            _buildParagraph(
              'If the App allows you to upload photographs, reviews, feedback, or other content, we may process that content to provide the relevant functionality.',
            ),
            _buildParagraph('For example, users or property owners may provide:'),
            _buildBulletPoint('Property photographs'),
            _buildBulletPoint('Profile photographs'),
            _buildBulletPoint('Reviews'),
            _buildBulletPoint('Ratings'),
            _buildBulletPoint('Feedback'),
            _buildBulletPoint('Listing information'),
            _buildParagraph(
              'You should not upload sensitive personal information, government identification documents, financial information, passwords, or information belonging to another person unless the feature specifically requires it and you are legally permitted to provide it.',
            ),
            _buildParagraph(
              'Where images or content are publicly displayed as part of a listing, review, profile or other platform feature, that content may be visible to other users.',
            ),
            _buildDivider(),

            // 6. HOW WE USE YOUR INFORMATION
            _buildSectionHeader('6. HOW WE USE YOUR INFORMATION'),
            _buildParagraph('We may use information for the following purposes:'),
            
            _buildSubHeader('Providing the Services'),
            _buildBulletPoint('Create and manage accounts'),
            _buildBulletPoint('Provide search and discovery functionality'),
            _buildBulletPoint('Display relevant accommodation listings'),
            _buildBulletPoint('Facilitate enquiries'),
            _buildBulletPoint('Facilitate booking requests where available'),
            _buildBulletPoint('Connect users with property owners/managers'),
            _buildBulletPoint('Provide customer support'),

            _buildSubHeader('Communication'),
            _buildParagraph('We may use your contact information to send:'),
            _buildBulletPoint('Account-related communications'),
            _buildBulletPoint('Booking/enquiry communications'),
            _buildBulletPoint('Verification communications'),
            _buildBulletPoint('Service notifications'),
            _buildBulletPoint('Security alerts'),
            _buildBulletPoint('Important changes to the Services'),
            _buildBulletPoint('Policy updates'),

            _buildSubHeader('Security'),
            _buildParagraph('We may process information to:'),
            _buildBulletPoint('Detect fraudulent activity'),
            _buildBulletPoint('Prevent abuse'),
            _buildBulletPoint('Protect accounts'),
            _buildBulletPoint('Investigate suspicious activity'),
            _buildBulletPoint('Protect our systems'),
            _buildBulletPoint('Enforce our Terms & Conditions'),

            _buildSubHeader('Improvement'),
            _buildParagraph('We may analyse aggregated or appropriately protected usage information to:'),
            _buildBulletPoint('Improve App functionality'),
            _buildBulletPoint('Understand user behaviour'),
            _buildBulletPoint('Identify technical problems'),
            _buildBulletPoint('Improve search and discovery'),
            _buildBulletPoint('Develop new features'),
            _buildBulletPoint('Improve user experience'),

            _buildSubHeader('Legal compliance'),
            _buildParagraph('We may process and disclose information where necessary to:'),
            _buildBulletPoint('Comply with applicable laws'),
            _buildBulletPoint('Respond to lawful government requests'),
            _buildBulletPoint('Protect legal rights'),
            _buildBulletPoint('Investigate suspected unlawful activity'),
            _buildBulletPoint('Prevent fraud or security incidents'),
            _buildDivider(),

            // 7. SHARING OF INFORMATION
            _buildSectionHeader('7. SHARING OF INFORMATION'),
            _buildParagraph('We do not sell your personal information as a product.'),
            _buildParagraph('We may share information in the circumstances described below:'),

            _buildSubHeader('7.1 Property Owners or Managers'),
            _buildParagraph(
              'When you voluntarily initiate an enquiry, booking request, or similar interaction with a property, we may share relevant information with the applicable property owner, manager, or representative so that they can respond to your request.',
            ),
            _buildParagraph('For example, this may include:'),
            _buildBulletPoint('Name'),
            _buildBulletPoint('Phone number'),
            _buildBulletPoint('Email address'),
            _buildBulletPoint('Booking/enquiry details'),
            _buildBulletPoint('Relevant accommodation preferences'),
            _buildParagraph(
              'Similarly, where appropriate, we may provide you with contact information relating to the relevant property. This sharing is part of the core functionality of MessKhojo.',
            ),

            _buildSubHeader('7.2 Service Providers'),
            _buildParagraph(
              'We may use third-party service providers to operate the App, such as providers of cloud hosting, data storage, authentication, analytics, crash reporting, communication services, maps and location services, security services, and technical infrastructure.',
            ),
            _buildParagraph(
              'These providers may process information on our behalf and are expected to handle information in accordance with applicable requirements and contractual obligations.',
            ),
            _buildParagraph(
              'Google Play makes developers responsible for ensuring third-party SDKs used in their apps comply with Google Play’s User Data requirements.',
            ),

            _buildSubHeader('7.3 Legal and Regulatory Authorities'),
            _buildParagraph('We may disclose information where reasonably necessary to:'),
            _buildBulletPoint('Comply with applicable law'),
            _buildBulletPoint('Respond to legal process'),
            _buildBulletPoint('Protect users'),
            _buildBulletPoint('Protect MessKhojo'),
            _buildBulletPoint('Investigate fraud or unlawful activity'),
            _buildBulletPoint('Respond to valid governmental requests'),

            _buildSubHeader('7.4 Business Transfers'),
            _buildParagraph(
              'If MessKhojo is involved in a merger, acquisition, restructuring, financing, sale of assets, or similar corporate transaction, information may be transferred as part of that transaction, subject to applicable law.',
            ),
            _buildDivider(),

            // 8. GOOGLE SERVICES AND APIS
            _buildSectionHeader('8. GOOGLE SERVICES AND APIS'),
            _buildParagraph(
              'Where MessKhojo uses Google services or APIs, such as Google Maps Platform, authentication services, analytics, Firebase services, or other Google APIs, information may be processed by Google according to the applicable Google terms and privacy practices.',
            ),
            _buildParagraph(
              'Our actual use of Google services will be limited to the functionality implemented in the App. Where Google API user data is involved, MessKhojo will comply with applicable Google API Services User Data Policy requirements, including Limited Use requirements where applicable.',
            ),
            _buildDivider(),

            // 9. THIRD-PARTY SERVICES AND LINKS
            _buildSectionHeader('9. THIRD-PARTY SERVICES AND LINKS'),
            _buildParagraph(
              'The App may contain links to or integrations with third-party services. Third parties may have their own privacy policies and terms. MessKhojo is not responsible for the independent privacy practices of third parties outside our control. You should review the privacy policies of third-party services before providing information directly to them.',
            ),
            _buildDivider(),

            // 10. COOKIES AND SIMILAR TECHNOLOGIES
            _buildSectionHeader('10. COOKIES AND SIMILAR TECHNOLOGIES'),
            _buildParagraph(
              'The MessKhojo website may use cookies and similar technologies. The App may use technologies such as analytics identifiers, SDKs, logs, or similar technical mechanisms necessary for security, performance, analytics, crash reporting, and App functionality.',
            ),
            _buildParagraph(
              'The specific technologies used may change as the App evolves. Where legally or technically required, we will provide appropriate disclosures and controls.',
            ),
            _buildDivider(),

            // 11. ADVERTISING AND MARKETING
            _buildSectionHeader('11. ADVERTISING AND MARKETING'),
            _buildParagraph(
              'If MessKhojo introduces advertising or personalised marketing features, the applicable data practices will be disclosed through this Privacy Policy and, where required, through appropriate consent or controls.',
            ),
            _buildParagraph(
              'We will not represent that advertising-related data practices exist unless they are actually implemented. Users may have choices regarding promotional communications, subject to applicable law.',
            ),
            _buildDivider(),

            // 12. DATA SECURITY
            _buildSectionHeader('12. DATA SECURITY'),
            _buildParagraph(
              'We implement reasonable technical and organisational measures designed to protect personal information against unauthorised access, alteration, disclosure, loss, or destruction.',
            ),
            _buildParagraph('These measures may include:'),
            _buildBulletPoint('Encryption during transmission'),
            _buildBulletPoint('Access controls'),
            _buildBulletPoint('Authentication controls'),
            _buildBulletPoint('Security monitoring'),
            _buildBulletPoint('Secure infrastructure'),
            _buildBulletPoint('Limited employee/vendor access'),
            _buildBulletPoint('Backup and recovery procedures'),
            _buildParagraph(
              'However, no internet transmission or electronic storage system can be guaranteed to be completely secure.',
            ),
            _buildDivider(),

            // 13. DATA RETENTION
            _buildSectionHeader('13. DATA RETENTION'),
            _buildParagraph(
              'We retain personal information only for as long as reasonably necessary for the purposes described in this Privacy Policy, including:',
            ),
            _buildBulletPoint('Providing Services'),
            _buildBulletPoint('Maintaining accounts'),
            _buildBulletPoint('Security and fraud prevention'),
            _buildBulletPoint('Resolving disputes'),
            _buildBulletPoint('Meeting legal obligations'),
            _buildBulletPoint('Maintaining necessary business records'),
            _buildParagraph(
              'When information is no longer required, we will delete, anonymise, or securely isolate it, subject to applicable legal or legitimate retention requirements.',
            ),
            _buildDivider(),

            // 14. ACCOUNT DELETION
            _buildSectionHeader('14. ACCOUNT DELETION'),
            _buildParagraph(
              'If you create a MessKhojo account, you may request deletion of your account and associated personal information. MessKhojo will provide an accessible account-deletion mechanism within the App and an appropriate web-based mechanism.',
            ),
            _buildParagraph(
              'When an account deletion request is received, we will process the request in accordance with applicable law and our retention obligations.',
            ),
            _buildParagraph(
              'Certain information may need to be retained where required or permitted by law, or where reasonably necessary for security, fraud prevention, dispute resolution, or enforcement of legal obligations.',
            ),
            _buildDivider(),

            // 15. YOUR PRIVACY RIGHTS
            _buildSectionHeader('15. YOUR PRIVACY RIGHTS'),
            _buildParagraph(
              'Depending on applicable law, you may have rights concerning your personal information, which may include:',
            ),
            _buildBulletPoint('Requesting access to personal information'),
            _buildBulletPoint('Requesting correction of inaccurate information'),
            _buildBulletPoint('Requesting deletion'),
            _buildBulletPoint('Withdrawing consent where processing relies on consent'),
            _buildBulletPoint('Requesting information regarding processing'),
            _buildBulletPoint('Raising a grievance'),
            _buildBulletPoint('Exercising other rights provided under applicable law'),
            _buildParagraph(
              'Requests may be subject to applicable legal limitations and verification requirements.',
            ),
            _buildDivider(),

            // 16. MARKETING COMMUNICATIONS
            _buildSectionHeader('16. MARKETING COMMUNICATIONS'),
            _buildParagraph(
              'You may opt out of promotional communications where an opt-out mechanism is provided. However, we may continue sending essential service communications, including:',
            ),
            _buildBulletPoint('Security notices'),
            _buildBulletPoint('Account notifications'),
            _buildBulletPoint('Booking/enquiry updates'),
            _buildBulletPoint('Important service announcements'),
            _buildBulletPoint('Legal or policy updates'),
            _buildDivider(),

            // 17. CHILDREN’S PRIVACY
            _buildSectionHeader('17. CHILDREN’S PRIVACY'),
            _buildParagraph(
              'MessKhojo is not specifically designed as a children’s service. We do not knowingly seek to collect personal information from children in violation of applicable law. If we become aware that personal information has been collected from a child contrary to applicable requirements, we will take appropriate steps consistent with applicable law.',
            ),
            _buildDivider(),

            // 18. DATA ACCURACY
            _buildSectionHeader('18. DATA ACCURACY'),
            _buildParagraph(
              'You are responsible for ensuring that information you provide to MessKhojo is accurate, complete, and current. If your information changes, you should update it where the App provides such functionality or contact us.',
            ),
            _buildDivider(),

            // 19. USER-GENERATED CONTENT
            _buildSectionHeader('19. USER-GENERATED CONTENT'),
            _buildParagraph(
              'Reviews, ratings, photographs, feedback, listing information, and other content submitted through MessKhojo may be visible to other users depending on the feature.',
            ),
            _buildParagraph(
              'We may moderate, remove, restrict, or investigate content that violates our Terms & Conditions or applicable law.',
            ),
            _buildDivider(),

            // 20. PROPERTY OWNER INFORMATION
            _buildSectionHeader('20. PROPERTY OWNER INFORMATION'),
            _buildParagraph(
              'MessKhojo may display property-related information obtained from property owners/managers, publicly available sources, user submissions, and MessKhojo verification activities.',
            ),
            _buildParagraph('Property information may include:'),
            _buildBulletPoint('Property name'),
            _buildBulletPoint('Contact information'),
            _buildBulletPoint('Location'),
            _buildBulletPoint('Photographs'),
            _buildBulletPoint('Amenities'),
            _buildBulletPoint('Pricing'),
            _buildBulletPoint('Other listing information'),
            _buildParagraph(
              'Where appropriate, a property owner or authorised representative may request correction or removal of information, subject to verification and applicable law.',
            ),
            _buildDivider(),

            // 21. CHANGES TO THIS PRIVACY POLICY
            _buildSectionHeader('21. CHANGES TO THIS PRIVACY POLICY'),
            _buildParagraph(
              'We may update this Privacy Policy from time to time to reflect new features, changes in our business model, changes in data practices, changes in technology, changes in applicable law, and changes required by Google Play or other platforms.',
            ),
            _buildParagraph(
              'When we make material changes, we may provide appropriate notice through the App, website, email, or other reasonable means.',
            ),
            _buildParagraph(
              'The “Last Updated” date at the top of this Privacy Policy will indicate when it was most recently revised.',
            ),
            _buildDivider(),

            // 22. CONTACT AND GRIEVANCE
            _buildSectionHeader('22. CONTACT AND GRIEVANCE'),
            _buildParagraph(
              'If you have questions, concerns, or requests relating to your personal information or this Privacy Policy, you may contact us at:',
            ),
            _buildContactBox(
              'MessKhojo Privacy & Grievance Contact',
              [
                'MessKhojo',
                'Jayadebkasapa, Bardhanpur',
                'Balasore, Odisha – 756021, India',
                '',
                'Privacy / Data Contact: messkhojooperator@gmail.com',
                'General Contact: messkhojobalasore@gmail.com',
              ],
            ),
            _buildParagraph(
              'We will review and respond to privacy-related requests in accordance with applicable law.',
            ),
            _buildDivider(),

            // 23. GOVERNING LAW
            _buildSectionHeader('23. GOVERNING LAW'),
            _buildParagraph(
              'This Privacy Policy will be interpreted in accordance with applicable laws of India, subject to any mandatory rights or protections applicable to you.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildBrandHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MESSKHOJO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'PRIVACY POLICY',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          _buildBadge('Last Updated: 28/09/2026'),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.textGray,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
          fontFamily: 'Outfit',
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSubHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          color: Color(0xFF4B5563),
          fontFamily: 'Outfit',
          height: 1.55,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF4B5563),
                fontFamily: 'Outfit',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
    );
  }

  Widget _buildNoticeBox(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF92400E),
          fontFamily: 'Outfit',
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildContactBox(String title, List<String> lines) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => line.isEmpty
                ? const SizedBox(height: 6)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                        fontFamily: 'Outfit',
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
