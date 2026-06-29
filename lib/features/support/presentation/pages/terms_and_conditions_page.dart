import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/content_section_header.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/profile_subpage_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

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
      title: 'Terms and Conditions',
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
                const ContentSectionHeader(title: 'Our Terms and Conditions'),
                const SizedBox(height: 18),
                Text(
                  'Welcome to Carro Care!',
                  style: AppTypography.quicksand(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 14),
                const _TermsBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  const _TermsBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _TermsParagraph(
          "These terms and conditions outline the rules and regulations for the use of Carro Care's Website, located at carrocare.in.",
        ),
        const _TermsParagraph(
          'By accessing this website we assume you accept these terms and conditions. Do not continue to use Carro Care if you do not agree to take all of the terms and conditions stated on this page. Our Terms and Conditions were created with the help of the Terms And Conditions Generator and the Free Terms & Conditions Generator.',
        ),
        const _TermsParagraph(
          'The following terminology applies to these Terms and Conditions, Privacy Statement and Disclaimer Notice and all Agreements: "Client", "You" and "Your" refers to you, the person log on this website and compliant to the Company’s terms and conditions. "The Company", "Ourselves", "We", "Our" and "Us", refers to our Company. "Party", "Parties", or "Us", refers to both the Client and ourselves. All terms refer to the offer, acceptance and consideration of payment necessary to undertake the process of our assistance to the Client in the most appropriate manner for the express purpose of meeting the Client’s needs in respect of provision of the Company’s stated services, in accordance with and subject to, prevailing law of Netherlands. Any use of the above terminology or other words in the singular, plural, capitalization and/or he/she or they, are taken as interchangeable and therefore as referring to the same.',
        ),
        const _TermsHeading('Cookies'),
        const _TermsParagraph(
          'We employ the use of cookies. By accessing Carro Care, you agreed to use cookies in agreement with the Carro Care\'s Privacy Policy.',
        ),
        const _TermsParagraph(
          'Most interactive websites use cookies to let us retrieve the user’s details for each visit. Cookies are used by our website to enable the functionality of certain areas to make it easier for people visiting our website. Some of our affiliate/advertising partners may also use cookies.',
        ),
        const _TermsHeading('License'),
        const _TermsParagraph(
          'Unless otherwise stated, Carro Care and/or its licensors own the intellectual property rights for all material on Carro Care. All intellectual property rights are reserved. You may access this from Carro Care for your own personal use subjected to restrictions set in these terms and conditions.',
        ),
        const _TermsParagraph('You must not:'),
        const _TermsBulletList(
          items: <String>[
            'Republish material from Carro Care',
            'Sell, rent or sub-license material from Carro Care',
            'Reproduce, duplicate or copy material from Carro Care',
            'Redistribute content from Carro Care',
          ],
        ),
        const _TermsParagraph('This Agreement shall begin on the date hereof.'),
        const _TermsParagraph(
          'Parts of this website offer an opportunity for users to post and exchange opinions and information in certain areas of the website. Carro Care does not filter, edit, publish or review Comments prior to their presence on the website. Comments do not reflect the views and opinions of Carro Care,its agents and/or affiliates. Comments reflect the views and opinions of the person who post their views and opinions. To the extent permitted by applicable laws, Carro Care shall not be liable for the Comments or for any liability, damages or expenses caused and/or suffered as a result of any use of and/or posting of and/or appearance of the Comments on this website.',
        ),
        const _TermsParagraph(
          'Carro Care reserves the right to monitor all Comments and to remove any Comments which can be considered inappropriate, offensive or causes breach of these Terms and Conditions.',
        ),
        const _TermsParagraph('You warrant and represent that:'),
        const _TermsBulletList(
          items: <String>[
            'You are entitled to post the Comments on our website and have all necessary licenses and consents to do so;',
            'The Comments do not invade any intellectual property right, including without limitation copyright, patent or trademark of any third party;',
            'The Comments do not contain any defamatory, libelous, offensive, indecent or otherwise unlawful material which is an invasion of privacy',
            'The Comments will not be used to solicit or promote business or custom or present commercial activities or unlawful activity.',
          ],
        ),
        const _TermsParagraph(
          'You hereby grant Carro Care a non-exclusive license to use, reproduce, edit and authorize others to use, reproduce and edit any of your Comments in any and all forms, formats or media.',
        ),
        const _TermsHeading('Hyperlinking to our Content'),
        const _TermsParagraph(
          'The following organizations may link to our Website without prior written approval:',
        ),
        const _TermsBulletList(
          items: <String>[
            'Government agencies;',
            'Search engines;',
            'News organizations;',
            'Online directory distributors may link to our Website in the same manner as they hyperlink to the Websites of other listed businesses; and',
            'System wide Accredited Businesses except soliciting non-profit organizations, charity shopping malls, and charity fundraising groups which may not hyperlink to our Website.',
          ],
        ),
        const _TermsParagraph(
          'These organizations may link to our home page, to publications or to other Website information so long as the link: (a) is not in any way deceptive; (b) does not falsely imply sponsorship, endorsement or approval of the linking party and its products and/or services; and (c) fits within the context of the linking party’s site.',
        ),
        const _TermsParagraph(
          'We may consider and approve other link requests from the following types of organizations:',
        ),
        const _TermsBulletList(
          items: <String>[
            'commonly-known consumer and/or business information sources;',
            'dot.com community sites;',
            'associations or other groups representing charities;',
            'online directory distributors;',
            'internet portals;',
            'accounting, law and consulting firms; and',
            'educational institutions and trade associations.',
          ],
        ),
        const _TermsParagraph(
          'We will approve link requests from these organizations if we decide that: (a) the link would not make us look unfavorably to ourselves or to our accredited businesses; (b) the organization does not have any negative records with us; (c) the benefit to us from the visibility of the hyperlink compensates the absence of Carro Care; and (d) the link is in the context of general resource information.',
        ),
        const _TermsParagraph(
          'These organizations may link to our home page so long as the link: (a) is not in any way deceptive; (b) does not falsely imply sponsorship, endorsement or approval of the linking party and its products or services; and (c) fits within the context of the linking party’s site.',
        ),
        const _TermsParagraph(
          'If you are one of the organizations listed in paragraph 2 above and are interested in linking to our website, you must inform us by sending an email to Carro Care. Please include your name, your organization name, contact information as well as the URL of your site, a list of any URLs from which you intend to link to our Website, and a list of the URLs on our site to which you would like to link. Wait 2-3 weeks for a response.',
        ),
        const _TermsParagraph(
          'Approved organizations may hyperlink to our Website as follows:',
        ),
        const _TermsBulletList(
          items: <String>[
            'By use of our corporate name; or',
            'By use of the uniform resource locator being linked to; or',
            'By use of any other description of our Website being linked to that makes sense within the context and format of content on the linking party’s site.',
          ],
        ),
        const _TermsParagraph(
          "No use of Carro Care's logo or other artwork will be allowed for linking absent a trademark license agreement.",
        ),
        const _TermsHeading('iFrames'),
        const _TermsParagraph(
          'Without prior approval and written permission, you may not create frames around our Web Pages that alter in any way the visual presentation or appearance of our Website.',
        ),
        const _TermsHeading('Content Liability'),
        const _TermsParagraph(
          'We shall not be held responsible for any content that appears on your Website. You agree to protect and defend us against all claims that are rising on your Website. No link(s) should appear on any Website that may be interpreted as libelous, obscene or criminal, or which infringes, otherwise violates, or advocates the infringement or other violation of, any third party rights.',
        ),
        const _TermsHeading('Your Privacy'),
        const _TermsParagraph('Please read Privacy Policy'),
        const _TermsHeading('Reservation of Rights'),
        const _TermsParagraph(
          'We reserve the right to request that you remove all links or any particular link to our Website. You approve to immediately remove all links to our Website upon request. We also reserve the right to amend these terms and conditions and it’s linking policy at any time. By continuously linking to our Website, you agree to be bound to and follow these linking terms and conditions.',
        ),
        const _TermsHeading('Removal of links from our website'),
        const _TermsParagraph(
          'If you find any link on our Website that is offensive for any reason, you are free to contact and inform us any moment. We will consider requests to remove links but we are not obligated to or so or to respond to you directly.',
        ),
        const _TermsParagraph(
          'We do not ensure that the information on this website is correct, we do not warrant its completeness or accuracy; nor do we promise to ensure that the website remains available or that the material on the website is kept up to date.',
        ),
        const _TermsHeading('Disclaimer'),
        const _TermsParagraph(
          'To the maximum extent permitted by applicable law, we exclude all representations, warranties and conditions relating to our website and the use of this website. Nothing in this disclaimer will:',
        ),
        const _TermsBulletList(
          items: <String>[
            'limit or exclude our or your liability for death or personal injury;',
            'limit or exclude our or your liability for fraud or fraudulent misrepresentation;',
            'limit any of our or your liabilities in any way that is not permitted under applicable law; or',
            'exclude any of our or your liabilities that may not be excluded under applicable law.',
          ],
        ),
        const _TermsParagraph(
          'The limitations and prohibitions of liability set in this Section and elsewhere in this disclaimer: (a) are subject to the preceding paragraph; and (b) govern all liabilities arising under the disclaimer, including liabilities arising in contract, in tort and for breach of statutory duty.',
        ),
        const _TermsParagraph(
          'As long as the website and the information and services on the website are provided free of charge, we will not be liable for any loss or damage of any nature.',
        ),
      ],
    );
  }
}

class _TermsHeading extends StatelessWidget {
  const _TermsHeading(this.text);

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

class _TermsParagraph extends StatelessWidget {
  const _TermsParagraph(this.text);

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

class _TermsBulletList extends StatelessWidget {
  const _TermsBulletList({required this.items});

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
