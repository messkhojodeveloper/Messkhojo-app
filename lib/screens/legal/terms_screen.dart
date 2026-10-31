import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
            
            // Welcome & Intro
            _buildParagraph(
              'Welcome to MessKhojo.',
              isBold: true,
            ),
            _buildParagraph(
              'These Terms & Conditions (“Terms”, “Terms and Conditions”) constitute a legally binding agreement between MessKhojo (“MessKhojo”, “we”, “us”, or “our”) and the person accessing or using our website, mobile application, and related services (“User”, “you”, or “your”).',
            ),
            _buildParagraph(
              'These Terms govern your access to and use of the MessKhojo website, mobile application, and related services (collectively, the “Platform”).',
            ),
            _buildParagraph(
              'By downloading, installing, accessing, registering for, or using the Platform, you acknowledge that you have read, understood, and agreed to these Terms.',
            ),
            _buildNoticeBox(
              'If you do not agree with these Terms, please do not access or use the Platform.',
            ),
            const SizedBox(height: 16),
            _buildDivider(),

            // 1. ABOUT MESSKHOJO
            _buildSectionHeader('1. ABOUT MESSKHOJO'),
            _buildSubHeader('1.1 Nature of the Platform'),
            _buildParagraph(
              'MessKhojo is an online discovery and intermediary platform designed to help students, working professionals, and other individuals discover and connect with accommodation providers, including messes, hostels, PGs and similar accommodation options.',
            ),
            _buildParagraph('The Platform may allow users to:'),
            _buildBulletPoint('Search for accommodation;'),
            _buildBulletPoint('Discover accommodation based on location;'),
            _buildBulletPoint('Filter and compare available options;'),
            _buildBulletPoint('View property information;'),
            _buildBulletPoint('View photographs, facilities and other listing information;'),
            _buildBulletPoint('View pricing information;'),
            _buildBulletPoint('Contact property owners or managers;'),
            _buildBulletPoint('Submit enquiries or booking requests;'),
            _buildBulletPoint('View ratings and reviews;'),
            _buildBulletPoint('Save or interact with listings;'),
            _buildBulletPoint('Submit feedback; and'),
            _buildBulletPoint('Use other features introduced by MessKhojo from time to time.'),
            
            _buildSubHeader('1.2 MessKhojo’s Role'),
            _buildParagraph(
              'MessKhojo acts primarily as an online intermediary and discovery platform connecting users (“Tenants”) with property owners, managers, or accommodation providers (“Hosts”).',
            ),
            _buildParagraph(
              'Unless expressly stated otherwise, MessKhojo does not own, sell, rent, manage, operate, furnish, or control the properties displayed on the Platform.',
            ),
            _buildParagraph(
              'MessKhojo is not itself the landlord, property owner, accommodation provider, or insurer merely because a property is displayed or discovered through the Platform.',
            ),

            _buildSubHeader('1.3 Independent Providers'),
            _buildParagraph(
              'The accommodation displayed on MessKhojo may be owned or operated by independent Hosts.',
            ),
            _buildParagraph(
              'The agreement concerning the actual accommodation, including occupancy, rent, deposit, rules, facilities, and other arrangements, is generally between the Tenant and the Host.',
            ),
            _buildParagraph(
              'MessKhojo is not a party to such private arrangements unless expressly stated otherwise.',
            ),
            _buildDivider(),

            // 2. LISTINGS
            _buildSectionHeader('2. LISTINGS'),
            _buildSubHeader('2.1 Types of Listings'),
            _buildParagraph('MessKhojo may display different categories of listings, including:'),
            _buildParagraph('MessKhojo Verified Listings', isBold: true),
            _buildParagraph(
              'These are listings that MessKhojo may have physically visited or otherwise verified according to its internal verification process. Verification is limited to the scope and date of the particular verification activity.',
            ),
            _buildParagraph('A verified listing does not mean that:'),
            _buildBulletPoint('The property will remain in the same condition;'),
            _buildBulletPoint('Every property detail is permanently accurate;'),
            _buildBulletPoint('The property is legally compliant in every respect;'),
            _buildBulletPoint('The Host will always provide the advertised services;'),
            _buildBulletPoint('The property is suitable for every user.'),
            _buildParagraph('Property conditions and information may change after verification.'),
            
            _buildParagraph('User-Sourced Listings', isBold: true),
            _buildParagraph(
              'Some listings may be created or populated using information submitted by users, students, Hosts, members of the public, or other sources. MessKhojo may not physically inspect every such listing.',
            ),
            _buildParagraph(
              'Accordingly, users should independently verify important information before entering into any arrangement.',
            ),
            _buildDivider(),

            // 3. SOURCES OF LISTING INFORMATION
            _buildSectionHeader('3. SOURCES OF LISTING INFORMATION'),
            _buildParagraph('Property-related information displayed on MessKhojo may be obtained from:'),
            _buildBulletPoint('Hosts or property managers;'),
            _buildBulletPoint('Information voluntarily submitted by users;'),
            _buildBulletPoint('Publicly available sources;'),
            _buildBulletPoint('Information collected or verified by MessKhojo;'),
            _buildBulletPoint('Other legitimate sources.'),
            _buildParagraph('Such information may include:'),
            _buildBulletPoint('Property name;'),
            _buildBulletPoint('Owner or manager information;'),
            _buildBulletPoint('Contact details;'),
            _buildBulletPoint('Location;'),
            _buildBulletPoint('Photographs;'),
            _buildBulletPoint('Pricing;'),
            _buildBulletPoint('Facilities;'),
            _buildBulletPoint('Amenities;'),
            _buildBulletPoint('Accommodation details;'),
            _buildBulletPoint('Rules;'),
            _buildBulletPoint('Other listing information.'),
            _buildParagraph(
              'MessKhojo may update, correct, modify, restrict, or remove listing information where appropriate.',
            ),
            _buildDivider(),

            // 4. PROPERTY OWNERSHIP AND LEGAL COMPLIANCE
            _buildSectionHeader('4. PROPERTY OWNERSHIP AND LEGAL COMPLIANCE'),
            _buildParagraph(
              'MessKhojo does not independently guarantee the legal status or ownership of every property listed on the Platform. Unless expressly stated otherwise, MessKhojo does not verify or guarantee:',
            ),
            _buildBulletPoint('Ownership title;'),
            _buildBulletPoint('Property registration;'),
            _buildBulletPoint('Rental permissions;'),
            _buildBulletPoint('Licences;'),
            _buildBulletPoint('Zoning permissions;'),
            _buildBulletPoint('Electricity approvals;'),
            _buildBulletPoint('Water approvals;'),
            _buildBulletPoint('Fire-safety compliance;'),
            _buildBulletPoint('Municipal compliance;'),
            _buildBulletPoint('Building approvals;'),
            _buildBulletPoint('Other statutory or regulatory requirements.'),
            _buildParagraph(
              'The Host is responsible for ensuring that the property operated by them complies with applicable laws and regulations.',
            ),
            _buildParagraph(
              'If MessKhojo becomes aware of potentially unlawful, fraudulent, unsafe, or materially misleading information, it may investigate, restrict, modify, suspend, or remove the relevant listing.',
            ),
            _buildDivider(),

            // 5. SEARCH, FILTERS AND RECOMMENDATIONS
            _buildSectionHeader('5. SEARCH, FILTERS AND RECOMMENDATIONS'),
            _buildParagraph(
              'MessKhojo may provide search, filtering, sorting, ranking, comparison, or recommendation features. Results may depend on factors including:',
            ),
            _buildBulletPoint('Location;'),
            _buildBulletPoint('Search terms;'),
            _buildBulletPoint('User-selected preferences;'),
            _buildBulletPoint('Budget;'),
            _buildBulletPoint('Listing information;'),
            _buildBulletPoint('Availability;'),
            _buildBulletPoint('Relevance;'),
            _buildBulletPoint('Verification status;'),
            _buildBulletPoint('Platform functionality;'),
            _buildBulletPoint('Other legitimate ranking factors.'),
            _buildParagraph(
              'The position of a listing in search results does not necessarily constitute an endorsement or guarantee by MessKhojo.',
            ),
            _buildDivider(),

            // 6. ACCOUNT REGISTRATION
            _buildSectionHeader('6. ACCOUNT REGISTRATION'),
            _buildParagraph(
              'Certain features may require users to create an account. When creating an account, you agree to provide accurate, current, and complete information.',
            ),
            _buildParagraph('You must not:'),
            _buildBulletPoint('Create an account using false information;'),
            _buildBulletPoint('Impersonate another person;'),
            _buildBulletPoint('Create an account for fraudulent purposes;'),
            _buildBulletPoint('Use another person’s account without permission;'),
            _buildBulletPoint('Provide another person’s personal information without lawful authority.'),
            _buildParagraph(
              'You are responsible for maintaining the security of your account credentials and authentication information.',
            ),
            _buildDivider(),

            // 7. ACCOUNT SECURITY
            _buildSectionHeader('7. ACCOUNT SECURITY'),
            _buildParagraph(
              'You are responsible for taking reasonable steps to protect your account. You must not share passwords, OTPs, authentication codes, or other security credentials with unauthorised persons.',
            ),
            _buildParagraph(
              'If you suspect unauthorised access to your account, you should contact MessKhojo promptly.',
            ),
            _buildParagraph(
              'MessKhojo may temporarily restrict an account where reasonably necessary to protect users, the Platform, or security.',
            ),
            _buildDivider(),

            // 8. BOOKING REQUESTS
            _buildSectionHeader('8. BOOKING REQUESTS'),
            _buildParagraph(
              'Where booking functionality is available, submitting a booking request through MessKhojo constitutes a request or offer to obtain accommodation and does not by itself guarantee acceptance or availability.',
            ),
            _buildParagraph(
              'A booking is considered confirmed only when the applicable confirmation process has been completed and MessKhojo or the relevant Host has communicated confirmation.',
            ),
            _buildParagraph('Submitting a booking request does not guarantee:'),
            _buildBulletPoint('Availability;'),
            _buildBulletPoint('Acceptance by the Host;'),
            _buildBulletPoint('Property suitability;'),
            _buildBulletPoint('Legal compliance;'),
            _buildBulletPoint('Particular facilities;'),
            _buildBulletPoint('Particular room conditions.'),
            _buildDivider(),

            // 9. BOOKING VERIFICATION
            _buildSectionHeader('9. BOOKING VERIFICATION'),
            _buildParagraph(
              'Where MessKhojo operates a booking verification process, our support team may contact you through available communication channels, including telephone, WhatsApp, email, in-app communication, or other legitimate communication methods.',
            ),
            _buildParagraph('The purpose may include verifying:'),
            _buildBulletPoint('Your identity or contact information;'),
            _buildBulletPoint('Your booking intent;'),
            _buildBulletPoint('Accommodation requirements;'),
            _buildBulletPoint('Booking details.'),
            _buildParagraph('You agree to cooperate reasonably with the verification process.'),
            _buildParagraph(
              'If you fail to respond after reasonable attempts, MessKhojo may cancel or close the booking request.',
            ),
            _buildDivider(),

            // 10. SHARING OF CONTACT INFORMATION
            _buildSectionHeader('10. SHARING OF CONTACT INFORMATION'),
            _buildParagraph(
              'When you voluntarily initiate an enquiry or booking interaction with a Host, MessKhojo may share relevant contact or booking information with that Host to facilitate communication.',
            ),
            _buildParagraph(
              'Similarly, MessKhojo may provide relevant Host contact information to the user. Such sharing is part of the Platform’s core intermediary functionality.',
            ),
            _buildParagraph(
              'The handling of information by Hosts after it has been shared may also be subject to the Host’s own legal and privacy obligations.',
            ),
            _buildParagraph(
              'For details regarding personal-data processing, please refer to the MessKhojo Privacy Policy.',
            ),
            _buildDivider(),

            // 11. CANCELLATION
            _buildSectionHeader('11. CANCELLATION'),
            _buildSubHeader('11.1 Before Confirmation'),
            _buildParagraph(
              'Where applicable, users may cancel a booking request before confirmation through the available Platform mechanism or by contacting MessKhojo.',
            ),
            _buildSubHeader('11.2 After Confirmation'),
            _buildParagraph(
              'Once a booking has been confirmed, cancellation may require contacting MessKhojo support and/or the relevant Host. The applicable cancellation conditions may depend on the specific booking and Host.',
            ),
            _buildParagraph(
              'Repeated unjustified cancellations or misuse of the booking system may result in restrictions on the user’s account.',
            ),
            _buildDivider(),

            // 12. PAYMENTS AND FEES
            _buildSectionHeader('12. PAYMENTS AND FEES'),
            _buildSubHeader('12.1 Current Platform Model'),
            _buildParagraph(
              'As of the date of these Terms, MessKhojo does not currently charge commission or service fees to Tenants or Hosts for using the Platform, unless expressly stated otherwise for a particular service or promotion.',
            ),
            _buildSubHeader('12.2 Direct Payments'),
            _buildParagraph(
              'Where accommodation payments, rent, security deposits, advances, or other amounts are payable directly to a Host, those payments are transactions between the Tenant and Host. MessKhojo does not currently process, hold, or transfer such accommodation payments unless expressly stated otherwise.',
            ),
            _buildSubHeader('12.3 Payment Disputes'),
            _buildParagraph('Where MessKhojo does not process the payment, disputes concerning:'),
            _buildBulletPoint('Rent;'),
            _buildBulletPoint('Deposits;'),
            _buildBulletPoint('Advances;'),
            _buildBulletPoint('Refunds;'),
            _buildBulletPoint('Payment failures;'),
            _buildBulletPoint('Charges;'),
            _buildBulletPoint('Payment receipts'),
            _buildParagraph(
              'are primarily between the Tenant and Host. MessKhojo may assist with communication where reasonably possible but does not guarantee resolution of such disputes.',
            ),
            _buildSubHeader('12.4 Future Payment Features'),
            _buildParagraph(
              'If MessKhojo introduces online payment, subscriptions, commissions, paid services, or other monetisation mechanisms, additional terms may apply. The applicable pricing, payment, cancellation, and refund terms will be communicated to users where required.',
            ),
            _buildDivider(),

            // 13. PROMOTIONAL CASHBACK AND OFFERS
            _buildSectionHeader('13. PROMOTIONAL CASHBACK AND OFFERS'),
            _buildParagraph(
              'MessKhojo may introduce promotional offers, rewards, cashback, coupons, referral benefits, or similar incentives. Such promotions may be subject to additional terms, eligibility criteria, expiry dates, limits, verification requirements, or other conditions.',
            ),
            _buildParagraph('Unless expressly stated otherwise, promotional benefits:'),
            _buildBulletPoint('Are not guaranteed;'),
            _buildBulletPoint('May be withdrawn where permitted;'),
            _buildBulletPoint('May not be transferable;'),
            _buildBulletPoint('May be subject to fraud or abuse checks.'),
            _buildParagraph(
              'MessKhojo may refuse or cancel promotional benefits where it reasonably believes they have been obtained through misuse, fraud, or violation of applicable terms.',
            ),
            _buildDivider(),

            // 14. UTILITIES AND PROPERTY-RELATED PAYMENTS
            _buildSectionHeader('14. UTILITIES AND PROPERTY-RELATED PAYMENTS'),
            _buildParagraph('MessKhojo does not generally verify or guarantee the payment status of:'),
            _buildBulletPoint('Electricity bills;'),
            _buildBulletPoint('Water bills;'),
            _buildBulletPoint('Maintenance charges;'),
            _buildBulletPoint('Municipal dues;'),
            _buildBulletPoint('Internet charges;'),
            _buildBulletPoint('Other property-related expenses.'),
            _buildParagraph(
              'Any disagreement regarding such expenses is generally between the Tenant and Host. Users should clarify applicable charges and responsibilities with the Host before entering into an accommodation arrangement.',
            ),
            _buildDivider(),

            // 15. USER RESPONSIBILITIES
            _buildSectionHeader('15. USER RESPONSIBILITIES'),
            _buildParagraph('You agree to:'),
            _buildBulletPoint('Provide accurate information;'),
            _buildBulletPoint('Use the Platform lawfully;'),
            _buildBulletPoint('Respect Hosts and other users;'),
            _buildBulletPoint('Follow applicable property rules;'),
            _buildBulletPoint('Respect contractual arrangements entered into with Hosts;'),
            _buildBulletPoint('Verify important accommodation information before committing;'),
            _buildBulletPoint('Protect your account credentials;'),
            _buildBulletPoint('Use the Platform responsibly.'),
            _buildParagraph(
              'You are responsible for your conduct when interacting with Hosts and using accommodation.',
            ),
            _buildDivider(),

            // 16. HOST RULES
            _buildSectionHeader('16. HOST RULES'),
            _buildParagraph(
              'Individual properties may have their own rules and conditions. These may include rules relating to:',
            ),
            _buildBulletPoint('Entry and exit;'),
            _buildBulletPoint('Visitors;'),
            _buildBulletPoint('Curfew;'),
            _buildBulletPoint('Occupancy;'),
            _buildBulletPoint('Property use;'),
            _buildBulletPoint('Behaviour;'),
            _buildBulletPoint('Payments;'),
            _buildBulletPoint('Maintenance;'),
            _buildBulletPoint('Security;'),
            _buildBulletPoint('Other property-specific requirements.'),
            _buildParagraph(
              'MessKhojo does not generally create or control Host-specific rules. Users should review and understand applicable Host rules before agreeing to stay at a property.',
            ),
            _buildDivider(),

            // 17. PROPERTY DAMAGE AND PERSONAL CONDUCT
            _buildSectionHeader('17. PROPERTY DAMAGE AND PERSONAL CONDUCT'),
            _buildParagraph('Users are responsible for their conduct at any accommodation they occupy.'),
            _buildParagraph(
              'Damage to property, theft, violations of Host rules, or similar incidents are generally matters between the Tenant and Host. MessKhojo is not responsible for damage caused by a user to a Host’s property.',
            ),
            _buildParagraph(
              'Likewise, MessKhojo does not guarantee the conduct of an independent Host or other occupant.',
            ),
            _buildParagraph('Nothing in these Terms limits rights that cannot legally be excluded.'),
            _buildDivider(),

            // 18. REVIEWS AND RATINGS
            _buildSectionHeader('18. REVIEWS AND RATINGS'),
            _buildParagraph(
              'MessKhojo may allow users to rate or review properties. Reviews should be based on genuine experiences and should be honest, relevant, and non-misleading.',
            ),
            _buildParagraph('You must not:'),
            _buildBulletPoint('Create fake reviews;'),
            _buildBulletPoint('Manipulate ratings;'),
            _buildBulletPoint('Review a property without a genuine basis;'),
            _buildBulletPoint('Threaten a Host with a negative review;'),
            _buildBulletPoint('Offer or accept improper incentives for reviews;'),
            _buildBulletPoint('Impersonate another person;'),
            _buildBulletPoint('Post defamatory or unlawful material;'),
            _buildBulletPoint('Include another person’s private information without appropriate authority.'),
            _buildParagraph(
              'MessKhojo may moderate, restrict, or remove reviews that violate these Terms or applicable law. MessKhojo does not guarantee that every review is accurate or represents the views of MessKhojo.',
            ),
            _buildDivider(),

            // 19. FEEDBACK AND COMPLAINTS
            _buildSectionHeader('19. FEEDBACK AND COMPLAINTS'),
            _buildParagraph(
              'Users may submit feedback or complaints through the Platform or available support channels. Where appropriate, MessKhojo may communicate a complaint to the relevant Host and facilitate communication between the parties.',
            ),
            _buildParagraph(
              'MessKhojo is not a judicial authority and generally cannot compel an independent Host to:',
            ),
            _buildBulletPoint('Provide a refund;'),
            _buildBulletPoint('Change property conditions;'),
            _buildBulletPoint('Accept a complaint;'),
            _buildBulletPoint('Modify a contract;'),
            _buildBulletPoint('Provide compensation.'),
            _buildParagraph('Nothing in this section limits any legal rights available to a user.'),
            _buildDivider(),

            // 20. CLAIMING OR CORRECTING LISTINGS
            _buildSectionHeader('20. CLAIMING OR CORRECTING LISTINGS'),
            _buildParagraph(
              'A Host or authorised representative may request to claim, modify, correct, or remove a listing. MessKhojo may request reasonable information to verify the claimant’s authority.',
            ),
            _buildParagraph('After verification, MessKhojo may:'),
            _buildBulletPoint('Update information;'),
            _buildBulletPoint('Transfer listing management;'),
            _buildBulletPoint('Correct inaccurate information;'),
            _buildBulletPoint('Remove information;'),
            _buildBulletPoint('Remove the listing where appropriate.'),
            _buildParagraph('Until verification is completed, MessKhojo may retain the listing in its existing form.'),
            _buildDivider(),

            // 21. USER-GENERATED CONTENT
            _buildSectionHeader('21. USER-GENERATED CONTENT'),
            _buildParagraph(
              'Users may submit photographs, reviews, ratings, comments, feedback, or other content. You represent that you have the necessary rights to submit such content.',
            ),
            _buildParagraph('You must not submit content that:'),
            _buildBulletPoint('Is unlawful;'),
            _buildBulletPoint('Is fraudulent;'),
            _buildBulletPoint('Infringes intellectual-property rights;'),
            _buildBulletPoint('Violates privacy;'),
            _buildBulletPoint('Contains malicious software;'),
            _buildBulletPoint('Is abusive or threatening;'),
            _buildBulletPoint('Is materially misleading;'),
            _buildBulletPoint('Contains unnecessary sensitive personal information.'),
            _buildParagraph(
              'By submitting content, you grant MessKhojo a non-exclusive, worldwide, royalty-free licence to host, reproduce, display, distribute, adapt, and use the content as reasonably necessary to operate, improve, and promote the Platform.',
            ),
            _buildParagraph('MessKhojo may remove or restrict content that violates these Terms or applicable law.'),
            _buildDivider(),

            // 22. PROHIBITED ACTIVITIES
            _buildSectionHeader('22. PROHIBITED ACTIVITIES'),
            _buildParagraph('You must not use MessKhojo to:'),
            _buildNumberedItem(1, 'Commit fraud;'),
            _buildNumberedItem(2, 'Impersonate another person;'),
            _buildNumberedItem(3, 'Create fraudulent accounts;'),
            _buildNumberedItem(4, 'Submit false information;'),
            _buildNumberedItem(5, 'Manipulate reviews;'),
            _buildNumberedItem(6, 'Harass or threaten users or Hosts;'),
            _buildNumberedItem(7, 'Upload malware;'),
            _buildNumberedItem(8, 'Attempt unauthorised access;'),
            _buildNumberedItem(9, 'Circumvent Platform security;'),
            _buildNumberedItem(10, 'Scrape or systematically extract data without permission;'),
            _buildNumberedItem(11, 'Use bots or automated systems to abuse the Platform;'),
            _buildNumberedItem(12, 'Interfere with Platform operation;'),
            _buildNumberedItem(13, 'Reverse engineer the Platform except where legally permitted;'),
            _buildNumberedItem(14, 'Copy substantial Platform content without permission;'),
            _buildNumberedItem(15, 'Conduct unlawful commercial activity;'),
            _buildNumberedItem(16, 'Violate another person’s privacy;'),
            _buildNumberedItem(17, 'Infringe intellectual-property rights;'),
            _buildNumberedItem(18, 'Use the Platform for unlawful purposes;'),
            _buildNumberedItem(19, 'Attempt to exploit vulnerabilities;'),
            _buildNumberedItem(20, 'Encourage another person to violate these Terms.'),
            _buildDivider(),

            // 23. HOST RESPONSIBILITIES
            _buildSectionHeader('23. HOST RESPONSIBILITIES'),
            _buildParagraph(
              'Hosts using MessKhojo are responsible for ensuring that information they provide is accurate and lawful.',
            ),
            _buildParagraph('Hosts must not:'),
            _buildBulletPoint('Create fraudulent listings;'),
            _buildBulletPoint('Misrepresent property facilities;'),
            _buildBulletPoint('Misrepresent pricing;'),
            _buildBulletPoint('Upload misleading photographs;'),
            _buildBulletPoint('Manipulate reviews;'),
            _buildBulletPoint('Harass users;'),
            _buildBulletPoint('Misuse user information;'),
            _buildBulletPoint('Engage in discriminatory unlawful conduct;'),
            _buildBulletPoint('Provide materially false information;'),
            _buildBulletPoint('Use the Platform for fraudulent purposes.'),
            _buildParagraph(
              'Hosts are responsible for complying with applicable laws governing their property and activities.',
            ),
            _buildDivider(),

            // 24. VERIFICATION
            _buildSectionHeader('24. VERIFICATION'),
            _buildParagraph(
              'MessKhojo may introduce verification badges, labels, or other indicators. Verification only indicates that MessKhojo has performed the particular verification activity associated with that designation.',
            ),
            _buildParagraph('It does not constitute a guarantee of:'),
            _buildBulletPoint('Property quality;'),
            _buildBulletPoint('Safety;'),
            _buildBulletPoint('Legal compliance;'),
            _buildBulletPoint('Permanent accuracy;'),
            _buildBulletPoint('Availability;'),
            _buildBulletPoint('Host behaviour;'),
            _buildBulletPoint('Future condition of the property.'),
            _buildDivider(),

            // 25. SAFETY AND INDEPENDENT VERIFICATION
            _buildSectionHeader('25. SAFETY AND INDEPENDENT VERIFICATION'),
            _buildParagraph(
              'Users should exercise reasonable caution before entering into any accommodation arrangement. Before making a commitment, users should independently verify information that is important to them, including:',
            ),
            _buildBulletPoint('Property location;'),
            _buildBulletPoint('Facilities;'),
            _buildBulletPoint('Pricing;'),
            _buildBulletPoint('Availability;'),
            _buildBulletPoint('Rules;'),
            _buildBulletPoint('Deposit requirements;'),
            _buildBulletPoint('Identity of the Host;'),
            _buildBulletPoint('Payment arrangements;'),
            _buildBulletPoint('Applicable accommodation conditions.'),
            _buildParagraph(
              'MessKhojo does not guarantee that an accommodation will meet every user’s expectations.',
            ),
            _buildDivider(),

            // 26. THIRD-PARTY SERVICES
            _buildSectionHeader('26. THIRD-PARTY SERVICES'),
            _buildParagraph(
              'The Platform may integrate third-party services, including services relating to maps, authentication, hosting, analytics, notifications, communications, security, and payments (where introduced).',
            ),
            _buildParagraph(
              'Use of third-party services may be subject to separate terms and policies. MessKhojo is not responsible for third-party services to the extent they operate independently of MessKhojo.',
            ),
            _buildDivider(),

            // 27. INTELLECTUAL PROPERTY
            _buildSectionHeader('27. INTELLECTUAL PROPERTY'),
            _buildParagraph(
              'All intellectual property in the Platform owned by or licensed to MessKhojo, including MessKhojo name, logo, brand identity, software, interface, graphics, design, original text, platform functionality, and other proprietary materials is protected by applicable law.',
            ),
            _buildParagraph(
              'Except as permitted by law or with written permission, you must not copy, reproduce, modify, distribute, sell, lease, license, or commercially exploit such materials.',
            ),
            _buildDivider(),

            // 28. TRADEMARKS
            _buildSectionHeader('28. TRADEMARKS'),
            _buildParagraph(
              'MessKhojo and its associated names, logos, marks, designs, and branding are owned by or licensed to MessKhojo. You may not use MessKhojo branding without prior written permission.',
            ),
            _buildDivider(),

            // 29. MOBILE APPLICATION LICENCE
            _buildSectionHeader('29. MOBILE APPLICATION LICENCE'),
            _buildParagraph(
              'Subject to these Terms, MessKhojo grants you a limited, non-exclusive, non-transferable, revocable licence to install and use the App for lawful personal use.',
            ),
            _buildParagraph('You must not:'),
            _buildBulletPoint('Copy or redistribute the App;'),
            _buildBulletPoint('Sell or sublicense the App;'),
            _buildBulletPoint('Modify the App;'),
            _buildBulletPoint('Attempt to extract source code;'),
            _buildBulletPoint('Circumvent technical restrictions;'),
            _buildBulletPoint('Use the App to build a competing service through unauthorised extraction or scraping.'),
            _buildParagraph('Nothing in these Terms restricts rights that cannot legally be restricted.'),
            _buildDivider(),

            // 30. GOOGLE PLAY AND APP STORE REQUIREMENTS
            _buildSectionHeader('30. GOOGLE PLAY AND APP STORE REQUIREMENTS'),
            _buildParagraph(
              'The MessKhojo App may be distributed through Google Play and other applicable app stores. Your use of the App is also subject to the relevant app store’s applicable terms and policies.',
            ),
            _buildParagraph(
              'MessKhojo may update the App where reasonably necessary to comply with platform requirements, security requirements, privacy requirements, applicable laws, and technical standards.',
            ),
            _buildParagraph(
              'Google Play’s policies may impose additional requirements relating to privacy, user data, permissions, account deletion, user-generated content, payments, and other areas. MessKhojo will seek to comply with requirements applicable to its Services.',
            ),
            _buildDivider(),

            // 31. PRIVACY
            _buildSectionHeader('31. PRIVACY'),
            _buildParagraph(
              'Your use of MessKhojo is also governed by the MessKhojo Privacy Policy. The Privacy Policy explains how MessKhojo collects, uses, stores, shares, and protects personal information.',
            ),
            _buildParagraph('The Privacy Policy forms an integral part of your relationship with MessKhojo.'),
            _buildDivider(),

            // 32. COMMUNICATIONS
            _buildSectionHeader('32. COMMUNICATIONS'),
            _buildParagraph(
              'MessKhojo may send communications necessary to operate the Platform, including OTPs, account notifications, booking-related communications, enquiry notifications, security alerts, important service announcements, and policy updates.',
            ),
            _buildParagraph(
              'Where permitted by law, MessKhojo may also send promotional communications. Users may opt out of promotional communications through available mechanisms. Essential service communications may continue where reasonably necessary.',
            ),
            _buildDivider(),

            // 33. PLATFORM AVAILABILITY
            _buildSectionHeader('33. PLATFORM AVAILABILITY'),
            _buildParagraph(
              'MessKhojo attempts to maintain reliable Platform availability but does not guarantee uninterrupted or error-free operation. The Platform may be temporarily unavailable because of maintenance, updates, technical problems, security measures, network failures, third-party service failures, or circumstances beyond our reasonable control.',
            ),
            _buildParagraph('MessKhojo may modify, suspend, or discontinue particular features.'),
            _buildDivider(),

            // 34. DISCLAIMER OF WARRANTIES
            _buildSectionHeader('34. DISCLAIMER OF WARRANTIES'),
            _buildParagraph(
              'To the maximum extent permitted by applicable law, the Platform is provided on an “as is” and “as available” basis. MessKhojo does not guarantee that:',
            ),
            _buildBulletPoint('The Platform will always be available;'),
            _buildBulletPoint('Information will always be complete or error-free;'),
            _buildBulletPoint('Every listing will be accurate;'),
            _buildBulletPoint('Every property will meet user expectations;'),
            _buildBulletPoint('Every Host will behave appropriately;'),
            _buildBulletPoint('A particular accommodation will be available;'),
            _buildBulletPoint('A booking request will be accepted.'),
            _buildParagraph('Nothing in these Terms excludes statutory rights that cannot legally be excluded.'),
            _buildDivider(),

            // 35. LIMITATION OF LIABILITY
            _buildSectionHeader('35. LIMITATION OF LIABILITY'),
            _buildParagraph(
              'To the maximum extent permitted by applicable law, MessKhojo shall not be liable for indirect, incidental, special, consequential, or punitive losses arising from or relating to:',
            ),
            _buildBulletPoint('Use of the Platform;'),
            _buildBulletPoint('Inability to use the Platform;'),
            _buildBulletPoint('Independent Host conduct;'),
            _buildBulletPoint('Property conditions;'),
            _buildBulletPoint('Property-related incidents;'),
            _buildBulletPoint('Incorrect or outdated listing information;'),
            _buildBulletPoint('User-to-Host disputes;'),
            _buildBulletPoint('Payment disputes where MessKhojo does not process the payment;'),
            _buildBulletPoint('Third-party services;'),
            _buildBulletPoint('Unauthorised conduct of third parties;'),
            _buildBulletPoint('Technical interruptions.'),
            _buildParagraph(
              'MessKhojo’s liability, if any, will be determined subject to applicable law. Nothing in these Terms excludes or limits liability that cannot legally be excluded or limited.',
            ),
            _buildDivider(),

            // 36. INDEMNIFICATION
            _buildSectionHeader('36. INDEMNIFICATION'),
            _buildParagraph(
              'To the extent permitted by applicable law, you agree to indemnify and hold harmless MessKhojo and its officers, employees, representatives, affiliates, and authorised personnel from claims, losses, liabilities, costs, and expenses arising from:',
            ),
            _buildBulletPoint('Your violation of these Terms;'),
            _buildBulletPoint('Your unlawful use of the Platform;'),
            _buildBulletPoint('Fraudulent activity;'),
            _buildBulletPoint('Your submitted content;'),
            _buildBulletPoint('Your violation of another person’s rights;'),
            _buildBulletPoint('Your dealings with Hosts;'),
            _buildBulletPoint('Your misuse of the Platform.'),
            _buildParagraph(
              'This provision does not apply to the extent that the relevant loss is caused by MessKhojo’s own unlawful conduct.',
            ),
            _buildDivider(),

            // 37. SUSPENSION OR TERMINATION
            _buildSectionHeader('37. SUSPENSION OR TERMINATION'),
            _buildParagraph(
              'MessKhojo may suspend, restrict, or terminate access to an account or listing where reasonably necessary, including where: these Terms are violated; fraud is suspected; illegal activity is suspected; false information is provided; Platform security is threatened; the Platform is abused; a listing is fraudulent; or a legal obligation requires action.',
            ),
            _buildParagraph(
              'Where appropriate, MessKhojo may provide notice or an opportunity to remedy a violation. Immediate action may be taken where reasonably necessary to protect users, the Platform, or legal rights.',
            ),
            _buildDivider(),

            // 38. ACCOUNT DELETION
            _buildSectionHeader('38. ACCOUNT DELETION'),
            _buildParagraph(
              'If you have created a MessKhojo account, you may request account deletion through the mechanism provided within the App and/or the designated web-based deletion mechanism.',
            ),
            _buildParagraph('Account deletion may result in loss of access to:'),
            _buildBulletPoint('Your account;'),
            _buildBulletPoint('Saved listings;'),
            _buildBulletPoint('Preferences;'),
            _buildBulletPoint('Reviews;'),
            _buildBulletPoint('Other account-associated features.'),
            _buildParagraph(
              'MessKhojo will process account deletion requests in accordance with its Privacy Policy and applicable law. Certain information may be retained where legally required or reasonably necessary for security, fraud prevention, dispute resolution, or legal compliance.',
            ),
            _buildDivider(),

            // 39. GRIEVANCE AND CUSTOMER SUPPORT
            _buildSectionHeader('39. GRIEVANCE AND CUSTOMER SUPPORT'),
            _buildParagraph(
              'For questions, complaints, listing issues, privacy concerns, or other Platform-related matters, users may contact MessKhojo through the available support channels:',
            ),
            _buildContactBox(
              'Grievance & Support Contacts',
              [
                'General Support: messkhojobalasore@gmail.com',
                'Privacy/Data Contact: messkhojooperator@gmail.com',
                'Telephone: +91 96928 19621',
              ],
            ),
            _buildParagraph(
              'MessKhojo will review complaints in accordance with applicable law and its internal procedures.',
            ),
            _buildDivider(),

            // 40. DISPUTES BETWEEN USERS AND HOSTS
            _buildSectionHeader('40. DISPUTES BETWEEN USERS AND HOSTS'),
            _buildParagraph(
              'Where a dispute concerns the actual accommodation or service provided by an independent Host, users should first attempt to resolve the matter directly with the Host.',
            ),
            _buildParagraph(
              'MessKhojo may facilitate communication where appropriate. However, MessKhojo does not guarantee that an independent Host will provide a refund, compensation, replacement accommodation, or other remedy.',
            ),
            _buildParagraph(
              'Nothing in these Terms prevents a user from exercising rights available under applicable law.',
            ),
            _buildDivider(),

            // 41. GOVERNING LAW
            _buildSectionHeader('41. GOVERNING LAW'),
            _buildParagraph(
              'These Terms shall be governed by and interpreted in accordance with the laws of India.',
            ),
            _buildParagraph(
              'Subject to applicable mandatory law, the courts having appropriate jurisdiction at Balasore, Odisha, India shall have jurisdiction over disputes arising in connection with these Terms or the Platform.',
            ),
            _buildDivider(),

            // 42. CHANGES TO THESE TERMS
            _buildSectionHeader('42. CHANGES TO THESE TERMS'),
            _buildParagraph(
              'MessKhojo may update these Terms from time to time to reflect new features, changes to the business model, new services, changes in data practices, changes in applicable law, regulatory requirements, security requirements, and changes to Platform functionality.',
            ),
            _buildParagraph(
              'Where changes are material, MessKhojo may provide reasonable notice through the App, website, email, or other appropriate means. The updated Terms will contain a revised “Last Updated” date.',
            ),
            _buildParagraph(
              'Your continued use of the Platform after the effective date of updated Terms may constitute acceptance of the revised Terms to the extent permitted by law.',
            ),
            _buildDivider(),

            // 43. SEVERABILITY
            _buildSectionHeader('43. SEVERABILITY'),
            _buildParagraph(
              'If any provision of these Terms is found to be invalid or unenforceable, that provision shall be interpreted to the maximum extent permitted by law, and the remaining provisions shall continue in effect.',
            ),
            _buildDivider(),

            // 44. NO WAIVER
            _buildSectionHeader('44. NO WAIVER'),
            _buildParagraph(
              'Failure by MessKhojo to enforce any provision of these Terms immediately does not constitute a waiver of its right to enforce that provision in the future.',
            ),
            _buildDivider(),

            // 45. ENTIRE AGREEMENT
            _buildSectionHeader('45. ENTIRE AGREEMENT'),
            _buildParagraph(
              'These Terms, together with the MessKhojo Privacy Policy and any additional terms expressly applicable to specific features, constitute the agreement governing your use of the Platform.',
            ),
            _buildParagraph(
              'Where a specific service has additional terms, those terms will apply to that service to the extent of any inconsistency.',
            ),
            _buildDivider(),

            // 46. CONTACT INFORMATION
            _buildSectionHeader('46. CONTACT INFORMATION'),
            _buildContactBox(
              'MessKhojo Official Contact Details',
              [
                'MessKhojo',
                'Jayadebkasapa, Bardhanpur',
                'Balasore, Odisha – 756021, India',
                '',
                'Email: messkhojobalasore@gmail.com',
                'Privacy/Data Contact: messkhojooperator@gmail.com',
                'Phone: +91 96928 19621',
                'Website: messkhojo.com',
              ],
            ),
            
            const SizedBox(height: 12),
            _buildNoticeBox(
              'By using MessKhojo, you acknowledge that you have read and understood these Terms & Conditions and agree to comply with them.',
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
            'TERMS & CONDITIONS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBadge('Last Updated: 28/09/2026'),
              const SizedBox(width: 8),
              _buildBadge('Effective Date: 28/09/2026'),
            ],
          ),
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

  Widget _buildParagraph(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          color: isBold ? AppTheme.textDark : const Color(0xFF4B5563),
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

  Widget _buildNumberedItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$number.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                fontFamily: 'Outfit',
              ),
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
