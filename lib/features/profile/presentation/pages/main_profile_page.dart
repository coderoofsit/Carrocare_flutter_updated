import 'package:carrocare_flutter/core/constants/app_urls.dart';
import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/auth_token_service.dart';
import 'package:carrocare_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/features/checkout/data/local/cart_local_storage.dart';
import 'package:carrocare_flutter/features/support/presentation/utils/profile_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _mainProfileLogoutRed = Color(0xFFEA2C1F);
const Color _mainProfileArrowGrey = Color(0xFF757575);

/// Matches Android [MainProfileActivity] / `activity_main_profile.xml`.
class MainProfilePage extends StatefulWidget {
  const MainProfilePage({super.key});

  @override
  State<MainProfilePage> createState() => _MainProfilePageState();
}

class _MainProfilePageState extends State<MainProfilePage> {
  String _name = '';
  String _mobile = '';
  String _versionLabel = 'Version 1.0.0\n© Carro Auto Pvt Ltd.';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final version = await ProfileActions.versionLabel();
    setState(() {
      _name = prefs.getString('username') ?? prefs.getString('name') ?? '';
      _mobile =
          prefs.getString('usermobile') ?? prefs.getString('mobile') ?? '';
      _versionLabel = version;
    });
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you want to exit ?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;
    await CartLocalStorage().clear();
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('customer_id') ?? '';
    final token = prefs.getString('token') ?? '';
    if (customerId.isNotEmpty && token.isNotEmpty) {
      try {
        await sl<AuthRemoteDataSource>().logout(
          customerId: customerId,
          token: token,
        );
      } catch (_) {}
    }
    await sl<AuthTokenService>().clearTokens();
    await prefs.clear();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Profile',
      onBack: () => context.go('/home'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: <Widget>[
                      _ProfileCard(
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: SvgPicture.asset(
                                'assets/vectors/ic_profile_24.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _name.isEmpty ? 'User' : _name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _mobile.isEmpty ? '-' : _mobile,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _mainProfileArrowGrey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      _ProfileCard(
                        child: Column(
                          children: <Widget>[
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_home.svg',
                              title: 'Home',
                              onTap: () => context.go('/home'),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_profile_24.svg',
                              title: 'Profile',
                              onTap: () => context.push('/profile'),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_orders_24.svg',
                              title: 'My Vehicle',
                              onTap: () => context.push('/my-vehicles'),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_orders_24.svg',
                              title: 'My Orders',
                              onTap: () => context.push('/my-orders'),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/images/ic_billings.png',
                              title: 'My Billings',
                              onTap: () => context.push('/my-billings'),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_about_24.svg',
                              title: 'About Us',
                              onTap: () => context.push('/about-us'),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_faqt_24.svg',
                              title: 'FAQ',
                              onTap: () => context.push('/faq'),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_terms_24.svg',
                              title: 'Terms and Conditions',
                              onTap: () => context.push('/terms-and-conditions'),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_contact_24.svg',
                              title: 'Contact Us',
                              onTap: () => context.push('/contact-us'),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_privacy_24.svg',
                              title: 'Privacy Policy',
                              onTap: () => context.push('/privacy-policy'),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_share_24.svg',
                              title: 'Share App',
                              onTap: () => ProfileActions.shareApp(context),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_rate_24.svg',
                              title: 'Rate Our App',
                              onTap: () => ProfileActions.rateApp(),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_cancel.svg',
                              title: 'Delete Account',
                              color: _mainProfileLogoutRed,
                              onTap: () => context.push('/delete-account'),
                            ),
                            _MenuRow(
                              iconAsset: 'assets/vectors/ic_logout_24.svg',
                              title: 'Logout',
                              color: _mainProfileLogoutRed,
                              showDivider: false,
                              onTap: _logout,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(AppUrls.muviereck);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Text(
                            _versionLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

/// White card with Android `bg_card_shadow` feel (3dp radius, soft elevation).
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14BBBDCB),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x0ABBBDCB),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.iconAsset,
    required this.title,
    required this.onTap,
    this.color = AppColors.black,
    this.showDivider = true,
  });

  final String iconAsset;
  final String title;
  final VoidCallback onTap;
  final Color color;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final bool tintIcon = color != AppColors.black;
    final Color arrowColor = color == _mainProfileLogoutRed
        ? _mainProfileLogoutRed
        : _mainProfileArrowGrey;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
            child: Row(
              children: <Widget>[
                if (iconAsset.endsWith('.png'))
                  Image.asset(
                    iconAsset,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  )
                else
                  SvgPicture.asset(
                    iconAsset,
                    width: 24,
                    height: 24,
                    colorFilter: tintIcon
                        ? ColorFilter.mode(color, BlendMode.srcIn)
                        : null,
                  ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: SvgPicture.asset(
                      'assets/vectors/ic_baseline_arrow_forward_ios_24.svg',
                      width: 16,
                      height: 16,
                      colorFilter:
                          ColorFilter.mode(arrowColor, BlendMode.srcIn),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: const Color(0xFFEDEFF1),
            ),
        ],
      ),
    );
  }
}
