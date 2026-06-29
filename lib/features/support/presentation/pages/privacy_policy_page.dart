import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/content_section_header.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/profile_subpage_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/main-profile');
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubpageScaffold(
      title: 'Privacy Policy',
      onBack: () => _onBack(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Card(
          elevation: 2,
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.grey200),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const ContentSectionHeader(title: 'Our Privacy Policy'),
                const SizedBox(height: 18),
                Text(
                  'Privacy Policy for Carro Care',
                  style: AppTypography.quicksand(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 14),
                const _PolicyBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicyBody extends StatelessWidget {
  const _PolicyBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _PolicyParagraph(
          'At Carro Care, accessible from carrocare.in, one of our main priorities is the privacy of our visitors. This Privacy Policy document contains types of information that is collected and recorded by Carro Care and how we use it.',
        ),
        const _PolicyParagraph(
          'If you have additional questions or require more information about our Privacy Policy, do not hesitate to contact us.',
        ),
        const _PolicyParagraph(
          'This Privacy Policy applies only to our online activities and is valid for visitors to our website with regards to the information that they shared and/or collect in Carro Care. This policy is not applicable to any information collected offline or via channels other than this website.',
        ),
        const _PolicyHeading('Consent'),
        const _PolicyParagraph(
          'By using our website, you hereby consent to our Privacy Policy and agree to its terms.',
        ),
        const _PolicyHeading('Information we collect'),
        const _PolicyParagraph(
          'The personal information that you are asked to provide, and the reasons why you are asked to provide it, will be made clear to you at the point we ask you to provide your personal information.',
        ),
        const _PolicyParagraph(
          'If you contact us directly, we may receive additional information about you such as your name, email address, phone number, the contents of the message and/or attachments you may send us, and any other information you may choose to provide.',
        ),
        const _PolicyParagraph(
          'When you register for an Account, we may ask for your contact information, including items such as name, company name, address, email address, and telephone number.',
        ),
        const _PolicyHeading('How we use your information'),
        const _PolicyParagraph(
          'We use the information we collect in various ways, including to:',
        ),
        const _PolicyBulletList(
          items: <String>[
            'Provide, operate, and maintain our website',
            'Improve, personalize, and expand our website',
            'Understand and analyze how you use our website',
            'Develop new products, services, features, and functionality',
            'Communicate with you, either directly or through one of our partners, including for customer service, to provide you with updates and other information relating to the website, and for marketing and promotional purposes',
            'Send you emails',
            'Find and prevent fraud',
          ],
        ),
        const _PolicyHeading('Log Files'),
        const _PolicyParagraph(
          "Carro Care follows a standard procedure of using log files. These files log visitors when they visit websites. All hosting companies do this and a part of hosting services' analytics. The information collected by log files include internet protocol (IP) addresses, browser type, Internet Service Provider (ISP), date and time stamp, referring/exit pages, and possibly the number of clicks. These are not linked to any information that is personally identifiable. The purpose of the information is for analyzing trends, administering the site, tracking users' movement on the website, and gathering demographic information. Our Privacy Policy was created with the help of the Privacy Policy Generator and the Privacy Policy Template.",
        ),
        const _PolicyHeading('Cookies and Web Beacons'),
        const _PolicyParagraph(
          "Like any other website, Carro Care uses 'cookies'. These cookies are used to store information including visitors' preferences, and the pages on the website that the visitor accessed or visited. The information is used to optimize the users' experience by customizing our web page content based on visitors' browser type and/or other information.",
        ),
        const _PolicyHeading('Advertising Partners Privacy Policies'),
        const _PolicyParagraph(
          'You may consult this list to find the Privacy Policy for each of the advertising partners of Carro Care.',
        ),
        const _PolicyParagraph(
          'Third-party ad servers or ad networks uses technologies like cookies, JavaScript, or Web Beacons that are used in their respective advertisements and links that appear on Carro Care, which are sent directly to users\' browser. They automatically receive your IP address when this occurs. These technologies are used to measure the effectiveness of their advertising campaigns and/or to personalize the advertising content that you see on websites that you visit.',
        ),
        const _PolicyParagraph(
          'Note that Carro Care has no access to or control over these cookies that are used by third-party advertisers.',
        ),
        const _PolicyHeading('Third Party Privacy Policies'),
        const _PolicyParagraph(
          "Carro Care's Privacy Policy does not apply to other advertisers or websites. Thus, we are advising you to consult the respective Privacy Policies of these third-party ad servers for more detailed information. It may include their practices and instructions about how to opt-out of certain options. You may find a complete list of these Privacy Policies and their links here: Privacy Policy Links.",
        ),
        const _PolicyParagraph(
          "You can choose to disable cookies through your individual browser options. To know more detailed information about cookie management with specific web browsers, it can be found at the browsers' respective websites. What Are Cookies?",
        ),
        const _PolicyHeading('CCPA Privacy Rights (Do Not Sell My Personal Information)'),
        const _PolicyParagraph(
          'Under the CCPA, among other rights, California consumers have the right to:',
        ),
        const _PolicyBulletList(
          items: <String>[
            "Request that a business that collects a consumer's personal data disclose the categories and specific pieces of personal data that a business has collected about consumers.",
            'Request that a business delete any personal data about the consumer that a business has collected.',
            "Request that a business that sells a consumer's personal data, not sell the consumer's personal data.",
          ],
        ),
        const _PolicyParagraph(
          'If you make a request, we have one month to respond to you. If you would like to exercise any of these rights, please contact us.',
        ),
        const _PolicyHeading('GDPR Data Protection Rights'),
        const _PolicyParagraph(
          'We would like to make sure you are fully aware of all of your data protection rights. Every user is entitled to the following:',
        ),
        const _PolicyBulletList(
          items: <String>[
            'The right to access – You have the right to request copies of your personal data. We may charge you a small fee for this service.',
            'The right to rectification – You have the right to request that we correct any information you believe is inaccurate. You also have the right to request that we complete the information you believe is incomplete.',
            'The right to erasure – You have the right to request that we erase your personal data, under certain conditions.',
            'The right to restrict processing – You have the right to request that we restrict the processing of your personal data, under certain conditions.',
            'The right to object to processing – You have the right to object to our processing of your personal data, under certain conditions.',
            'The right to data portability – You have the right to request that we transfer the data that we have collected to another organization, or directly to you, under certain conditions.',
          ],
        ),
        const _PolicyParagraph(
          'If you make a request, we have one month to respond to you. If you would like to exercise any of these rights, please contact us.',
        ),
        const _PolicyHeading("Children's Information"),
        const _PolicyParagraph(
          'Another part of our priority is adding protection for children while using the internet. We encourage parents and guardians to observe, participate in, and/or monitor and guide their online activity.',
        ),
        const _PolicyParagraph(
          'Carro Care does not knowingly collect any Personal Identifiable Information from children under the age of 13. If you think that your child provided this kind of information on our website, we strongly encourage you to contact us immediately and we will do our best efforts to promptly remove such information from our records.',
        ),
      ],
    );
  }
}

class _PolicyHeading extends StatelessWidget {
  const _PolicyHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: AppTypography.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.grey800,
        ),
      ),
    );
  }
}

class _PolicyParagraph extends StatelessWidget {
  const _PolicyParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppTypography.dmSans(
          fontSize: 14,
          color: AppColors.grey700,
          height: 1.5,
        ),
      ),
    );
  }
}

class _PolicyBulletList extends StatelessWidget {
  const _PolicyBulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey700,
                        height: 1.5,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.dmSans(
                          fontSize: 14,
                          color: AppColors.grey700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
