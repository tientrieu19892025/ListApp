# ListApp

**ListApp** là tweak màn hình chính (SpringBoard) hiện đại dành cho iOS đã jailbreak (iOS 15.0 – 27.x). Tweak **thay thế hoàn toàn màn hình chính truyền thống**, hiển thị danh sách ứng dụng theo phong cách Cài đặt (Settings) ngay khi mở khóa.

Mỗi ứng dụng được bọc trong một **khung kính lỏng (Liquid Glass) dài chiếm đúng 2/3 chiều ngang màn hình**, canh giữa ngay ngắn từ trên xuống dưới, đi kèm icon lớn sắc nét, tên ứng dụng và vệt sáng phản quang cao cấp.

---

## ✨ Điểm nổi bật & Cải tiến mới

- 🪟 **Thay thế hoàn toàn Màn hình chính**:
  - Khi mở khóa, màn hình sẽ hiển thị trực tiếp danh sách ứng dụng cuộn dọc siêu mượt mà.
  - Tự động ẩn hoàn toàn lưới icon mặc định, thanh Dock và dấu trang (Page Dots).
  - Khóa cuộn trang ngang của SpringBoard để tập trung tối đa cho danh sách app.

- 💊 **Thanh kính lỏng dài 2/3 màn hình (Elongated Liquid Glass Pills)**:
  - Mỗi ứng dụng là một viên capsule kính lỏng chiếm đúng **2/3 chiều ngang màn hình**, canh giữa tuyệt đối.
  - Hiệu ứng tán xạ kính lỏng (Liquid Glass Specular Reflection) chuẩn phong cách iOS 26/27.
  - Bên trái: Biểu tượng ứng dụng kích thước 42x42pt bo góc squircle liên tục.
  - Ở giữa: Tên ứng dụng to rõ, sắc nét với bóng chữ nhẹ chống chói.
  - Bên phải: Mũi tên chỉ hướng Settings (`›`) tinh tế.
  - Tự động thích ứng màu nền theo chế độ Sáng / Tối (Light / Dark mode).

- 🔍 **Thanh tìm kiếm nhanh**:
  - Thiết kế viên thuốc kính lỏng 2/3 màn hình nằm ở đỉnh danh sách.
  - Lọc ứng dụng theo thời gian thực tức thì khi gõ.

- 🛡️ **Bảo vệ hệ thống & Ổn định tuyệt đối**:
  - Đọc danh sách app trực tiếp từ bộ nhớ `SBApplicationController` của SpringBoard và fallback sang `LSApplicationWorkspace`.
  - Khởi chạy app 4 tầng bảo vệ chống crash và chống respring loop.
  - Hỗ trợ Chế độ nguồn điện thấp (Low Power Mode) và Giảm độ trong suốt.

- ⚙️ **Cài đặt & Đa ngôn ngữ (Preferences)**:
  - Đã tích hợp đầy đủ `Info.plist` với `NSPrincipalClass: LARootListController` giúp Cài đặt mở ngay lập tức, không bao giờ bị văng hay không phản hồi.
  - Hỗ trợ 4 ngôn ngữ: **Tiếng Việt (`vi`)**, **Tiếng Anh (`en`)**, **Tiếng Nhật (`ja`)**, **Tiếng Trung giản thể (`zh-Hans`)**.
  - Đầy đủ trang **Credits tác giả**, trang **Ủng hộ (Donate)** với Ko-fi, PayPal, GitHub Sponsors và MoMo/VietQR cho cộng đồng Việt Nam.

---

## 📦 Kiến trúc & 3 Bản đóng gói

Dự án hỗ trợ đóng gói đầy đủ cả 3 bản:
1. **Rootful** (`iphoneos-arm`): Dành cho các bản jailbreak rootful truyền thống.
2. **Rootless** (`iphoneos-arm64`): Dành cho Dopamine, Palera1n rootless,...
3. **RootHide** (`iphoneos-arm64e`): Dành cho RootHide Theos và môi trường ẩn jailbreak.

Lệnh đóng gói tất cả 3 bản:
```bash
./scripts/build-all.sh
```

---

## 💖 Tác giả & Giấy phép

- **Tác giả**: Jin Ken Nguyen
- **GitHub**: [github.com/jinkennguyen](https://github.com/jinkennguyen)
- **X / Twitter**: [x.com/jinkennguyen](https://x.com/jinkennguyen)
- **Ủng hộ**: [ko-fi.com/jinkennguyen](https://ko-fi.com/jinkennguyen) | [paypal.me/jinkennguyen](https://paypal.me/jinkennguyen)
- **Giấy phép**: MIT License.
