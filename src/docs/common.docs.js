/**
 * @swagger
 * components:
 *   schemas:
 *     Error:
 *       type: object
 *       properties:
 *         success:
 *           type: boolean
 *           example: false
 *         error:
 *           type: object
 *           properties:
 *             message:
 *               type: string
 *             details:
 *               type: array
 *               items:
 *                 type: object
 *     Pagination:
 *       type: object
 *       properties:
 *         page:
 *           type: integer
 *         limit:
 *           type: integer
 *         total:
 *           type: integer
 *         totalPages:
 *           type: integer
 *     User:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         email:
 *           type: string
 *         role:
 *           type: string
 *           enum: [ADMIN, CUSTOMER]
 *         name:
 *           type: string
 *         phone:
 *           type: string
 *           nullable: true
 *         isActive:
 *           type: boolean
 *         createdAt:
 *           type: string
 *         updatedAt:
 *           type: string
 *     AuthPayload:
 *       type: object
 *       properties:
 *         user:
 *           $ref: "#/components/schemas/User"
 *         accessToken:
 *           type: string
 *         refreshToken:
 *           type: string
 *     Category:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         name:
 *           type: string
 *         slug:
 *           type: string
 *         description:
 *           type: string
 *           nullable: true
 *         imageUrl:
 *           type: string
 *           nullable: true
 *         parentId:
 *           type: string
 *           nullable: true
 *         createdAt:
 *           type: string
 *     ProductImage:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         url:
 *           type: string
 *         position:
 *           type: integer
 *     Product:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         title:
 *           type: string
 *         slug:
 *           type: string
 *         description:
 *           type: string
 *           nullable: true
 *         price:
 *           type: number
 *         compareAtPrice:
 *           type: number
 *           nullable: true
 *         sku:
 *           type: string
 *         stockQty:
 *           type: integer
 *         isActive:
 *           type: boolean
 *         categoryId:
 *           type: string
 *         category:
 *           $ref: "#/components/schemas/Category"
 *         images:
 *           type: array
 *           items:
 *             $ref: "#/components/schemas/ProductImage"
 *     Address:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         label:
 *           type: string
 *         street:
 *           type: string
 *         city:
 *           type: string
 *         country:
 *           type: string
 *         zip:
 *           type: string
 *           nullable: true
 *         isDefault:
 *           type: boolean
 *     Cart:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         items:
 *           type: array
 *           items:
 *             type: object
 *         subtotal:
 *           type: number
 *         itemCount:
 *           type: integer
 *     Order:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         status:
 *           type: string
 *           enum: [PENDING, PAID, SHIPPED, DELIVERED, CANCELLED]
 *         paymentStatus:
 *           type: string
 *           enum: [UNPAID, PAID, REFUNDED]
 *         subtotal:
 *           type: number
 *         shippingCost:
 *           type: number
 *         total:
 *           type: number
 *         shippingAddress:
 *           type: object
 *         items:
 *           type: array
 *           items:
 *             type: object
 *         createdAt:
 *           type: string
 *     Review:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         rating:
 *           type: integer
 *         comment:
 *           type: string
 *           nullable: true
 *         createdAt:
 *           type: string
 *         user:
 *           type: object
 */
export {};

