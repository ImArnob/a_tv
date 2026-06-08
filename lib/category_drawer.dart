import 'package:flutter/material.dart';

class CategoryDrawer extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryDrawer({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xff080B12),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xffEF4444), Color(0xff111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.live_tv_rounded, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Live TV',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Browse by category',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: categories.length,
                separatorBuilder: (context, index) {
                  return const Divider(height: 1, color: Colors.white10);
                },
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == selectedCategory;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.redAccent.withOpacity(0.15),
                    leading: Icon(
                      category == 'All Channels'
                          ? Icons.dashboard_rounded
                          : Icons.folder_rounded,
                      color: isSelected ? Colors.redAccent : Colors.white70,
                    ),
                    title: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.redAccent : Colors.white,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.redAccent,
                          )
                        : null,
                    onTap: () {
                      onCategorySelected(category);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
