import 'package:flutter/material.dart';
import 'package:reteno_plugin/reteno.dart';

class EcommerceEventsPage extends StatelessWidget {
  const EcommerceEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ecommerce Events'),
      ),
      body: SingleChildScrollView(
        child: Wrap(
          spacing: 4,
          children: [
            ElevatedButton(
              child: const Text('Log ProductViewed'),
              onPressed: () async {
                await Reteno().logEcommerceEvent(
                  RetenoEcommerceProductViewed(
                    product: const RetenoEcommerceProduct(
                      productId: 'product_id',
                      price: 10.0,
                      inStock: true,
                      attributes: {
                        'color': ['red', 'blue'],
                        'size': ['S', 'M'],
                      },
                    ),
                  ),
                );
                if (context.mounted) {
                  _showSnackBar(context, 'Product Viewed');
                }
              },
            ),
            ElevatedButton(
              child: const Text('Log CategoryViewed'),
              onPressed: () async {
                await Reteno().logEcommerceEvent(
                  RetenoEcommerceProductCategoryViewed(
                    category: const RetenoEcommerceCategory(
                      productCategoryId: 'category_id',
                      attributes: {
                        'color': ['red', 'blue']
                      },
                    ),
                  ),
                );
                if (context.mounted) {
                  _showSnackBar(context, 'Category Viewed');
                }
              },
            ),
            ElevatedButton(
              child: const Text('Log ProductAddedToWishlist'),
              onPressed: () async {
                await Reteno().logEcommerceEvent(
                  RetenoEcommerceProductAddedToWishlist(
                    product: const RetenoEcommerceProduct(
                      productId: 'product_id',
                      price: 10.0,
                      inStock: true,
                      attributes: {
                        'color': ['red', 'blue'],
                        'size': ['S', 'M'],
                      },
                    ),
                    currency: 'USD',
                  ),
                );
                if (context.mounted) {
                  _showSnackBar(context, 'Product Added To Wishlist');
                }
              },
            ),
            ElevatedButton(
              child: const Text('Log CartUpdated'),
              onPressed: () async {
                await Reteno().logEcommerceEvent(
                  RetenoEcommerceCartUpdated(
                    cartId: 'cart_id',
                    products: [
                      const RetenoEcommerceProductInCart(
                        productId: 'product_id',
                        price: 10.0,
                        quantity: 1,
                        discount: 0,
                        name: 'Product Name',
                        category: 'Category',
                        attributes: {
                          'color': ['red', 'blue'],
                          'size': ['S', 'M'],
                        },
                      )
                    ],
                    currency: 'USD',
                  ),
                );
                if (context.mounted) {
                  _showSnackBar(context, 'Product Added To Cart');
                }
              },
            ),
            ElevatedButton(
              child: const Text('Log OrderCreated'),
              onPressed: () async {
                await Reteno().logEcommerceEvent(
                  RetenoEcommerceOrderCreated(
                    order: RetenoEcommerceOrder(
                      externalOrderId: 'external_order_id',
                      totalCost: 10.0,
                      status: RetenoEcommerceOrderStatus.initialized,
                      date: DateTime.now().toIso8601String(),
                      cartId: 'cart_id',
                      email: 'email',
                      phone: 'phone',
                      firstName: 'first_name',
                      lastName: 'last_name',
                      shipping: null,
                      discount: null,
                      taxes: null,
                      restoreUrl: null,
                      statusDescription: null,
                      storeId: null,
                      source: null,
                      deliveryMethod: null,
                      paymentMethod: null,
                      deliveryAddress: null,
                      items: [
                        const RetenoEcommerceItem(
                          externalItemId: 'external_item_id',
                          name: 'Product Name',
                          category: 'Category',
                          cost: 10000,
                          quantity: 1,
                          url: 'https://example.com/product',
                          imageUrl: 'https://example.com/image.jpg',
                        ),
                      ],
                      attributes: {
                        'color': ['red', 'blue'],
                        'size': ['S', 'M'],
                      },
                    ),
                  ),
                );
                if (context.mounted) {
                  _showSnackBar(context, 'OrderCreated');
                }
              },
            ),
            ElevatedButton(
              child: const Text('Log OrderUpdated'),
              onPressed: () async {
                await Reteno().logEcommerceEvent(
                  RetenoEcommerceOrderUpdated(
                    order: RetenoEcommerceOrder(
                      externalOrderId: 'external_order_id',
                      totalCost: 10.0,
                      status: RetenoEcommerceOrderStatus.inProgress,
                      date: DateTime.now().toIso8601String(),
                      cartId: 'cart_id',
                      email: 'email',
                      phone: 'phone',
                      firstName: 'first_name',
                      lastName: 'last_name',
                      shipping: null,
                      discount: null,
                      taxes: null,
                      restoreUrl: null,
                      statusDescription: null,
                      storeId: null,
                      source: null,
                      deliveryMethod: null,
                      paymentMethod: null,
                      deliveryAddress: null,
                      items: null,
                      attributes: {
                        'color': ['red', 'blue'],
                        'size': ['S', 'M'],
                      },
                    ),
                  ),
                );
                if (context.mounted) {
                  _showSnackBar(context, 'OrderCreated');
                }
              },
            ),
            ElevatedButton(
              child: const Text('Log OrderDelivered'),
              onPressed: () async {
                await Reteno().logEcommerceEvent(
                  RetenoEcommerceOrderDelivered(
                    externalOrderId: 'external_order_id',
                  ),
                );
                if (context.mounted) {
                  _showSnackBar(context, 'OrderDelivered');
                }
              },
            ),
            ElevatedButton(
              child: const Text('Log OrderCancelled'),
              onPressed: () async {
                await Reteno().logEcommerceEvent(
                  RetenoEcommerceOrderCancelled(
                    externalOrderId: 'external_order_id',
                  ),
                );
                if (context.mounted) {
                  _showSnackBar(context, 'OrderCancelled');
                }
              },
            ),
            ElevatedButton(
              child: const Text('Log SearchRequest'),
              onPressed: () async {
                await Reteno().logEcommerceEvent(
                  RetenoEcommerceSearchRequest(
                    query: 'query',
                    isFound: true,
                  ),
                );
                if (context.mounted) {
                  _showSnackBar(context, 'SearchRequest');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: SingleChildScrollView(child: Text(text)),
    ));
  }
}
