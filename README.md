
# Bài tập lớn - Phát triển ứng dụng Task Mangager với Flutter

## Thông tin sinh viên
- **Họ và tên**: Đồng Ngọc Phúc
- **MSSV**: 2221050279  
- **Lớp**: DCCTCLC67B

## Giới thiệu
**Task Manager** là ứng dụng di động giúp người dùng quản lý công việc cá nhân hiệu quả, được xây dựng bằng **Flutter**. Ứng dụng tập trung vào trải nghiệm người dùng mượt mà, giao diện hiện đại và khả năng đồng bộ dữ liệu thời gian thực.
Dự án áp dụng kiến trúc **Clean Architecture** (tách biệt UI, Services, Models) và quy trình **CI/CD** tự động hóa để đảm bảo chất lượng mã nguồn.

## Công nghệ và Thư viện sử dụng
* **Framework:** Flutter (Dart).
* **Backend:** Firebase Authentication (Xác thực), Cloud Firestore (Cơ sở dữ liệu NoSQL Realtime).
* **State Management:** Provider (Quản lý trạng thái, Theme, Notification Service).
* **Local Features:**
    * `flutter_local_notifications`: Thông báo nhắc nhở cục bộ.
    * `timezone`: Xử lý múi giờ cho thông báo.
* **Testing & CI/CD:**
    * `flutter_test`: Kiểm thử Unit và Widget.
    * **GitHub Actions:** Tự động hóa quy trình Build và Test (Continuous Integration).

## Các chức năng của ứng dụng
### 1. **Xác thực người dùng:**
* Đăng ký, Đăng nhập (Email/Password).
* Đăng xuất.

### 2. **Quản lý Công việc (CRUD):**
* **Create:** Thêm công việc mới với Tiêu đề, Mô tả, Danh mục, Hạn chót (Ngày/Giờ).
* **Read:** Xem danh sách công việc. Hỗ trợ lọc theo Tab (Tất cả, Hôm nay, Tuần này, Tháng này).
* **Update:** Sửa nội dung công việc, Đánh dấu hoàn thành/chưa hoàn thành (Checkbox).
* **Delete:** Xóa công việc khỏi cơ sở dữ liệu.

### 3. **Tính năng nâng cao:**
* **Tìm kiếm (Search):** Tìm kiếm công việc theo tiêu đề (Realtime).
* **Thông báo (Notifications):** Thông báo khi đến hạn chót.
* **Giao diện:** Chế độ Tối/Sáng (Dark Mode/Light Mode) tùy chỉnh.
* **Cá nhân hóa:** Cập nhật Tên hiển thị, Đổi mật khẩu (có xác thực lại).
* **Đồng bộ hóa:** Dữ liệu được lưu trên Firebase gắn liền với tài khoản người dùng, dù có cài lại ứng dụng hay đổi thiết bị thì dữ liệu vẫn đồng bộ theo tài khoản.


### 4. Kiểm thử và CI/CD
* **Unit Test:** Kiểm tra tính đúng đắn của `TaskModel` (fromMap, toMap).
* **Widget Test:** Kiểm tra giao diện màn hình Đăng nhập (sự tồn tại của các nút, ô nhập liệu).
* **CI/CD Status:** Workflow đã chạy thành công (Success) trên GitHub Actions.

## Hướng dẫn cài đặt
1. Tải mã nguồn từ repository.
    ```bash
    git clone <đường dẫn tới repo>
    VD: git clone https://github.com/HUMG-IT/flutter-final-project-dnphuc1211.git
    ```

2. Cài đặt các dependencies:
   ```bash
   flutter pub get
   ```
3. Chạy ứng dụng:
   ```bash
   flutter run
   ```
4. Kiểm tra ứng dụng trên thiết bị hoặc máy ảo.
5. Đăng nhập hoặc tạo tài khoản mới.
6. Thực hiện các thao tác CRUD và kiểm tra kết quả.
7. Thực hiện kiểm thử tự động và xem kết quả:
    ```bash
    flutter test
    ```

## Video Demo
Link: 
## Bảng đánh giá kết quả

Dựa trên các tiêu chí chấm điểm của bài tập lớn, em xin tự đánh giá mức độ hoàn thiện của dự án như sau:

| Mức điểm | Tiêu chí yêu cầu | Kết quả thực hiện trong Dự án (Task Manager) | Đánh giá |
| :---: | :--- | :--- | :---: |
| **5/10** | **Build thành công (CI/CD)**<br>GitHub Actions báo "Success". | - Đã thiết lập workflow tại `.github/workflows/flutter_ci.yml`.<br>- Trạng thái Build & Test trên GitHub Actions: **Success**.<br>- Lệnh `flutter test` chạy thành công 100% trên máy local. | Đạt |
| **6/10** | **CRUD cơ bản**<br>Tạo, Đọc, Cập nhật, Xóa đối tượng chính. | - Đối tượng: **Công việc (Task)**.<br>- Chức năng: Thêm task mới, Xem danh sách task, Sửa nội dung task, Xóa task hoạt động ổn định. | Đạt |
| **7/10** | **Quản lý trạng thái & UI**<br>Không cần reload app, phản hồi thân thiện. | - Sử dụng **Provider** và **StreamBuilder** giúp giao diện cập nhật Realtime ngay khi dữ liệu thay đổi.<br>- Có thông báo phản hồi (SnackBar) khi thực hiện hành động.<br>- Sử dụng Dialog xác nhận khi xóa. | Đạt |
| **8/10** | **Tích hợp API/CSDL**<br>Kết nối Backend, xử lý lỗi. | - Tích hợp **Firebase Firestore** (Lưu trữ dữ liệu đám mây).<br>- Tích hợp **Firebase Authentication** (Quản lý người dùng).<br>- Xử lý các trường hợp lỗi (Try-catch) và hiển thị thông báo lỗi cụ thể. | Đạt |
| **9/10** | **Kiểm thử & Giao diện hoàn thiện**<br>Unit/Widget Test, Auth, Profile, UI hoàn chỉnh. | - **Testing:** Đã viết Unit Test cho `TaskModel` và Widget Test cho màn hình Login.<br>- **Auth:** Đầy đủ Đăng ký, Đăng nhập, Đăng xuất, Tự động đăng nhập.<br>- **Profile:** Cập nhật thông tin cá nhân, Đổi mật khẩu (có Re-auth).<br>- **UI:** Giao diện đẹp, hỗ trợ **Dark Mode / Light Mode**. | Đạt |
| **10/10** | **Tối ưu hóa & Nâng cao**<br>Tính năng nâng cao, Code sạch, CI/CD ổn định. | - **Nâng cao:** Tìm kiếm (Search), Lọc theo thời gian (Hôm nay/Tuần này), Sắp xếp task hoàn thành xuống dưới.<br>- **Thông báo:** Tích hợp **Local Notifications** nhắc nhở lịch hẹn.<br>- **Code:** Cấu trúc Clean Architecture (tách biệt Models, Services, Pages).<br>- **CI/CD:** Quy trình tự động hóa hoạt động ổn định. | Đạt |


## Tự đánh giá điểm: 10/10
Ứng dụng đã hoàn thiện vượt mức yêu cầu cơ bản, đảm bảo tính ổn định cao thông qua quy trình kiểm thử tự động và CI/CD. Giao diện người dùng được tối ưu hóa tốt cho trải nghiệm mượt mà.

## Lời cảm ơn
Em xin gửi lời cảm ơn chân thành đến thầy Trần Chung Chuyên đã tận tình giảng dạy và hướng dẫn em trong suốt quá trình học tập môn Phát triển ứng dụng di động đa nền tảng 1.

Nhờ những kiến thức quý báu và sự định hướng của thầy, em đã tiếp cận với công nghệ Flutter, Firebase cũng như quy trình làm việc chuyên nghiệp với CI/CD và Kiểm thử tự động. Đồ án này không chỉ là bài tập kết thúc môn học mà còn là cơ hội tuyệt vời để em rèn luyện kỹ năng thực tế cho công việc sau này.

Trong quá trình thực hiện, dù đã rất cố gắng nhưng chắc chắn không tránh khỏi những thiếu sót. Em rất mong nhận được những nhận xét và đóng góp ý kiến của thầy để hoàn thiện sản phẩm tốt hơn.

Kính chúc thầy thật nhiều sức khỏe và công tác tốt!
