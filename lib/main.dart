import 'package:flutter/material.dart';

void main() => runApp(const Nova());

enum Role { customer, restaurant, courier, admin }

class Product {
  final String name;
  final String store;
  final String emoji;
  final double price;
  const Product(this.name, this.store, this.emoji, this.price);
}

const products = <Product>[
  Product('برجر كلاسيك', 'برجر هاوس', '🍔', 120),
  Product('فراخ كرسبي', 'تشيكن تايم', '🍗', 145),
  Product('بيتزا مارجريتا', 'بيتزا بلس', '🍕', 180),
  Product('شاورما عربي', 'شاورما ستار', '🌯', 95),
  Product('باستا ألفريدو', 'إيطاليانو', '🍝', 160),
];

class Nova extends StatelessWidget {
  const Nova({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nova Delivery',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffff5a36)),
      ),
      home: const App(),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Role role = Role.customer;
  int tab = 0;
  final Map<Product, int> cart = <Product, int>{};

  void add(Product product) {
    setState(() {
      cart[product] = (cart[product] ?? 0) + 1;
    });
  }

  void sub(Product product) {
    setState(() {
      final count = cart[product] ?? 0;
      if (count <= 1) {
        cart.remove(product);
      } else {
        cart[product] = count - 1;
      }
    });
  }

  double get total => cart.entries.fold(
        0,
        (sum, entry) => sum + entry.key.price * entry.value,
      );

  void changeRole(Role newRole) {
    setState(() {
      role = newRole;
      tab = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (role != Role.customer) {
      return Panel(role: role, onRole: changeRole);
    }

    final pages = <Widget>[
      Home(add: add),
      Search(add: add),
      const Orders(),
      Cart(cart: cart, total: total, add: add, sub: sub),
      Profile(onRole: changeRole),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nova Delivery',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => tab = 3),
            icon: Badge(
              isLabelVisible: cart.isNotEmpty,
              label: Text(cart.length.toString()),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          IconButton(
            onPressed: () => notify(context),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'بحث',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'طلباتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag),
            label: 'السلة',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

class Home extends StatelessWidget {
  final void Function(Product) add;
  const Home({super.key, required this.add});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xffff5a36), Color(0xffff8a65)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'جوعان؟ 😋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'أكلك المفضل لحد باب البيت',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن مطعم أو وجبة...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'التصنيفات',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              '🍔 برجر',
              '🍕 بيتزا',
              '🍗 فراخ',
              '🌯 شاورما',
              '🍝 باستا',
              '🥗 صحي',
            ]
                .map(
                  (item) => SizedBox(
                    width: 90,
                    child: Card(
                      child: Center(
                        child: Text(item, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'الأكثر طلباً',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        ...products.map(
          (product) => Card(
            child: ListTile(
              leading: Text(
                product.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              title: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${product.store} • ${product.price.toStringAsFixed(0)} ج.م',
              ),
              trailing: IconButton.filled(
                onPressed: () => add(product),
                icon: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Search extends StatelessWidget {
  final void Function(Product) add;
  const Search({super.key, required this.add});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'ابحث...',
            border: OutlineInputBorder(),
          ),
        ),
        ...products.map(
          (product) => Card(
            child: ListTile(
              leading: Text(
                product.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              title: Text(product.name),
              subtitle: Text(product.store),
              trailing: IconButton.filled(
                onPressed: () => add(product),
                icon: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Orders extends StatelessWidget {
  const Orders({super.key});

  Widget order(String id, String status, String store) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
        title: Text('#$id'),
        subtitle: Text('$store • $status'),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'طلباتي',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        order('NV-1028', 'قيد التوصيل', 'برجر هاوس'),
        order('NV-1021', 'تم التسليم', 'بيتزا بلس'),
        order('NV-1009', 'ملغي', 'شاورما ستار'),
      ],
    );
  }
}

class Cart extends StatelessWidget {
  final Map<Product, int> cart;
  final double total;
  final void Function(Product) add;
  final void Function(Product) sub;

  const Cart({
    super.key,
    required this.cart,
    required this.total,
    required this.add,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    if (cart.isEmpty) {
      return const Center(
        child: Text(
          'السلة فارغة',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: cart.entries
                .map(
                  (entry) => Card(
                    child: ListTile(
                      leading: Text(
                        entry.key.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(entry.key.name),
                      subtitle: Text(
                        '${entry.key.price.toStringAsFixed(0)} ج.م',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => sub(entry.key),
                            icon: const Icon(Icons.remove),
                          ),
                          Text(entry.value.toString()),
                          IconButton(
                            onPressed: () => add(entry.key),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => checkout(context, total),
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: Text(
                    'تأكيد الطلب • ${total.toStringAsFixed(0)} ج.م',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Profile extends StatelessWidget {
  final void Function(Role) onRole;
  const Profile({super.key, required this.onRole});

  @override
  Widget build(BuildContext context) {
    const sections = [
      'بيانات الحساب',
      'العناوين',
      'طرق الدفع',
      'الكوبونات',
      'المفضلة',
      'الإشعارات',
      'الإعدادات',
      'الدعم',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 45,
          child: Icon(Icons.person, size: 45),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'حساب العميل',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        ...sections.map(
          (item) => Card(
            child: ListTile(
              title: Text(item),
              trailing: const Icon(Icons.chevron_left),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'لوحات النظام',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('مطعم'),
              onPressed: () => onRole(Role.restaurant),
            ),
            ActionChip(
              label: const Text('مندوب'),
              onPressed: () => onRole(Role.courier),
            ),
            ActionChip(
              label: const Text('مالك/إدارة'),
              onPressed: () => onRole(Role.admin),
            ),
          ],
        ),
      ],
    );
  }
}

class Panel extends StatelessWidget {
  final Role role;
  final void Function(Role) onRole;

  const Panel({super.key, required this.role, required this.onRole});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == Role.admin;
    final isRestaurant = role == Role.restaurant;

    final title = isAdmin
        ? 'لوحة المالك والإدارة'
        : isRestaurant
            ? 'لوحة المطعم'
            : 'لوحة المندوب';

    final sections = isAdmin
        ? [
            'إدارة الطلبات',
            'العملاء',
            'المطاعم',
            'المندوبون',
            'المدفوعات',
            'المحفظة',
            'الكوبونات والعروض',
            'التقارير والتحليلات',
            'الإشعارات',
            'الشكاوى',
            'الأدوار والصلاحيات',
            'إعدادات المنصة',
          ]
        : isRestaurant
            ? [
                'الطلبات',
                'قائمة الطعام والأسعار',
                'المخزون',
                'ساعات العمل',
                'العروض',
                'المبيعات والتقارير',
                'التقييمات',
                'إعدادات المطعم',
              ]
            : [
                'الطلبات المتاحة',
                'الطلبات الحالية',
                'الخريطة والتوجيه',
                'الأرباح والمحفظة',
                'سجل التوصيلات',
                'التقييمات',
                'بيانات المركبة',
                'الدعم',
              ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<Role>(
            onSelected: onRole,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: Role.customer,
                child: Text('العميل'),
              ),
              PopupMenuItem(
                value: Role.restaurant,
                child: Text('المطعم'),
              ),
              PopupMenuItem(
                value: Role.courier,
                child: Text('المندوب'),
              ),
              PopupMenuItem(
                value: Role.admin,
                child: Text('الإدارة'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            children: const [
              _MetricCard(title: 'الطلبات', value: '286'),
              _MetricCard(title: 'المبيعات', value: '48,620 ج.م'),
              _MetricCard(title: 'المطاعم', value: '124'),
              _MetricCard(title: 'المندوبون', value: '87'),
            ],
          ),
          ...sections.map(
            (item) => Card(
              child: ListTile(
                title: Text(item),
                leading: const Icon(Icons.settings_outlined),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فتح: $item')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.analytics),
            const Spacer(),
            Text(title),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void notify(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => const SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'الإشعارات',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(Icons.local_offer),
            title: Text('خصم 20% على طلبك القادم'),
          ),
          ListTile(
            leading: Icon(Icons.delivery_dining),
            title: Text('المندوب في الطريق'),
          ),
        ],
      ),
    ),
  );
}

void checkout(BuildContext context, double total) {
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'تأكيد الطلب',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const ListTile(
            leading: Icon(Icons.location_on),
            title: Text('عنوان التوصيل'),
            subtitle: Text('المنزل'),
          ),
          const ListTile(
            leading: Icon(Icons.payments),
            title: Text('الدفع'),
            subtitle: Text('الدفع عند الاستلام'),
          ),
          Text('الإجمالي: ${total.toStringAsFixed(0)} ج.م'),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إنشاء الطلب بنجاح 🎉')),
              );
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    ),
  );
}
