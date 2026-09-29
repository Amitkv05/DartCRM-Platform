class Menu {
  final int? id;
  final String? menuName;
  final String? childMenuName;
  final String? linkUrl;

  const Menu({this.id, this.menuName, this.childMenuName, this.linkUrl});

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: int.tryParse((json['id'] ?? json['Id'] ?? '').toString()),
      menuName: (json['menu_name'] ?? json['MenuName'] ?? '').toString(),
      childMenuName:
          (json['child_menu_name'] ?? json['ChildMenuName'] ?? '').toString(),
      linkUrl: (json['route_path'] ?? json['LinkURL'] ?? '').toString(),
    );
  }
}
