import '../models/food_item.dart';

const List<FoodItem> canteenMenuItems = [
  // --- SNACKS (5 Items) ---
  FoodItem(
    id: 'snack-1',
    name: 'Samosa (2 pcs)',
    category: FoodCategory.snacks,
    description:
        'Crispy golden triangular pastry crusts filled with a savory blend of spiced potatoes and tender green peas.\nServed piping hot alongside house-made tangy tamarind and refreshing mint chutneys.',
    prepTimeMinutes: 5,
    price: 20.0,
    imageUrl:
        'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'snack-2',
    name: 'Veg Puff',
    category: FoodCategory.snacks,
    description:
        'Delicate, multi-layered flaky golden pastry baked fresh in our canteen ovens daily.\nStuffed generously with seasoned garden vegetables, cumin seeds, and aromatic Indian spices.',
    prepTimeMinutes: 5,
    price: 25.0,
    imageUrl:
        'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'snack-3',
    name: 'Vada Pav',
    category: FoodCategory.snacks,
    description:
        'The quintessential Mumbai street snack with a spiced mashed potato ball batter-fried in chickpea flour.\nTucked inside a warm soft pav roll with zesty dry garlic coconut powder and green chili.',
    prepTimeMinutes: 5,
    price: 25.0,
    imageUrl:
        'https://images.unsplash.com/photo-1606491956689-2ea866880c84?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'snack-4',
    name: 'French Fries',
    category: FoodCategory.snacks,
    description:
        'Thick-cut, golden potato batons freshly deep-fried until exquisitely crisp on the outside and fluffy inside.\nLightly dusted with fine sea salt and our signature canteen herb-paprika seasoning.',
    prepTimeMinutes: 8,
    price: 50.0,
    imageUrl:
        'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'snack-5',
    name: 'Veg Sandwich',
    category: FoodCategory.snacks,
    description:
        'Freshly sliced soft white bread generously buttered and smeared with spicy coriander-mint chutney.\nStacked with garden-fresh tomatoes, crisp cucumbers, boiled potatoes, and chaat masala.',
    prepTimeMinutes: 7,
    price: 40.0,
    imageUrl:
        'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=600&q=80',
  ),

  // --- MEALS (6 Items) ---
  FoodItem(
    id: 'meal-1',
    name: 'Veg Thali',
    category: FoodCategory.meals,
    description:
        'Complete balanced nutritional meal featuring two warm whole-wheat rotis and fragrant steamed rice.\nAccompanied by homestyle yellow dal tadka, seasonal vegetable sabzi, crispy papad, and fresh salad.',
    prepTimeMinutes: 12,
    price: 90.0,
    imageUrl:
        'https://images.unsplash.com/photo-1610057099431-d73a1c9d2f2f?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'meal-2',
    name: 'Paneer Roll',
    category: FoodCategory.meals,
    description:
        'Succulent fresh paneer cubes marinated in rich tandoori herbs and lightly grilled to perfection.\nRolled inside a soft golden paratha with crunchy onion rings, bell peppers, and mint mayo.',
    prepTimeMinutes: 10,
    price: 60.0,
    imageUrl:
        'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'meal-3',
    name: 'Hakka Noodles (Veg)',
    category: FoodCategory.meals,
    description:
        'Chinese wok-tossed long wheat noodles prepared over high flame with fresh shredded carrots and cabbage.\nFinished with crisp bell peppers, scallions, and a fragrant garlic-infused soy seasoning.',
    prepTimeMinutes: 10,
    price: 70.0,
    imageUrl:
        'https://images.unsplash.com/photo-1585032226651-759b368d7246?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'meal-4',
    name: 'Veg Biryani',
    category: FoodCategory.meals,
    description:
        'Royal long-grain basmati rice dum-cooked on low flame with fresh cauliflower, beans, carrots, and peas.\nInfused with saffron milk, caramelized shallots, mint leaves, and served with cool cucumber raita.',
    prepTimeMinutes: 12,
    price: 90.0,
    imageUrl:
        'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'meal-5',
    name: 'Chole Bhature',
    category: FoodCategory.meals,
    description:
        'Rich and hearty North Indian Punjabi chickpea curry slowly simmered in an aromatic blend of dark spices.\nPaired with two large, fluffy, piping-hot ballooned bhaturas and house-pickled onions.',
    prepTimeMinutes: 10,
    price: 65.0,
    imageUrl:
        'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'meal-6',
    name: 'Masala Dosa',
    category: FoodCategory.meals,
    description:
        'Crispy paper-thin South Indian fermented rice-lentil crepe cooked to a rich golden brown hue.\nFilled with traditional mustard-spiced potato mash, served with piping hot vegetable sambar and coconut dip.',
    prepTimeMinutes: 10,
    price: 60.0,
    imageUrl:
        'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?auto=format&fit=crop&w=600&q=80',
  ),

  // --- BEVERAGES (3 Items) ---
  FoodItem(
    id: 'bev-1',
    name: 'Masala Chai',
    category: FoodCategory.beverages,
    description:
        'Classic steaming cup of Indian milk tea brewed with premium Assam tea leaves and full cream milk.\nInfused with freshly crushed green cardamom pods, fiery ginger root, and warm aromatic cloves.',
    prepTimeMinutes: 4,
    price: 15.0,
    imageUrl:
        'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'bev-2',
    name: 'Cold Coffee',
    category: FoodCategory.beverages,
    description:
        'Thick, velvety, and invigorating coffee milkshake blended with premium dark roast beans and ice cream.\nServed frosty in a tall glass with an indulgent chocolate syrup drizzle and cocoa dusting.',
    prepTimeMinutes: 5,
    price: 45.0,
    imageUrl:
        'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'bev-3',
    name: 'Fresh Lime Soda',
    category: FoodCategory.beverages,
    description:
        'Effervescent sparkling club soda squeezed with fresh tangy key limes over crushed ice cubes.\nCustom-balanced with Himalayan black salt, pure cane sugar syrup, and crushed fresh mint sprigs.',
    prepTimeMinutes: 4,
    price: 30.0,
    imageUrl:
        'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=600&q=80',
  ),

  // --- DESSERTS (2 Items) ---
  FoodItem(
    id: 'des-1',
    name: 'Chocolate Brownie',
    category: FoodCategory.desserts,
    description:
        'Decadent, rich, and eggless gourmet dark chocolate fudge brownie baked with Belgian cocoa.\nFeatures a lightly crinkled top, soft gooey center studded with dark chocolate chunks, served warm.',
    prepTimeMinutes: 3,
    price: 50.0,
    imageUrl:
        'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=600&q=80',
  ),
  FoodItem(
    id: 'des-2',
    name: 'Gulab Jamun (2 pcs)',
    category: FoodCategory.desserts,
    description:
        'Two traditional soft, melt-in-your-mouth golden fried milk solid dumplings.\nImmersed in hot sugar syrup fragrant with rose water, green cardamom powder, and saffron strands.',
    prepTimeMinutes: 3,
    price: 30.0,
    imageUrl:
        'https://images.unsplash.com/photo-1605197162446-2489868fbfa4?auto=format&fit=crop&w=600&q=80',
  ),
];
