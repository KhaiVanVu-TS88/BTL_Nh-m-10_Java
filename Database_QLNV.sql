CREATE DATABASE qlnv6;
USE qlnv6;

-- Bảng TuyenDung
CREATE TABLE TuyenDung (
    MaTuyenDung VARCHAR(10) PRIMARY KEY,
    HoTen VARCHAR(50) NOT NULL,
    SoDienThoai VARCHAR(15) NOT NULL UNIQUE,
    Email VARCHAR(50) NOT NULL UNIQUE,
    ChucVu VARCHAR(50) NOT NULL,
    TrinhDo VARCHAR(50) NOT NULL,
    MucLuongDeal INT NOT NULL,
    TrangThai VARCHAR(20) NOT NULL
);

-- Bảng PhongBan
CREATE TABLE PhongBan (
    MaPhongBan VARCHAR(10) PRIMARY KEY,
    TenPhongBan VARCHAR(50) NOT NULL,
    NgayThanhLap VARCHAR(10) NOT NULL,
    TruongPhong VARCHAR(50) NOT NULL,
    NgayNhanChuc VARCHAR(10) NOT NULL,
    SoLuongNhanVien INT NOT NULL,
    LuongTrungBinh INT NOT NULL
);

-- Bảng NhanVien
CREATE TABLE NhanVien (
    MaNhanVien VARCHAR(10) PRIMARY KEY,
    TenNhanVien VARCHAR(50) NOT NULL,
    GioiTinh VARCHAR(10) NOT NULL,
    NgaySinh VARCHAR(10) NOT NULL,
    DiaChi VARCHAR(100) NOT NULL,
    SoDienThoai VARCHAR(15) NOT NULL UNIQUE,
    MaPhongBan VARCHAR(10) NOT NULL,
    ChucVu VARCHAR(50) NOT NULL,
    MucLuong INT NOT NULL,
    FOREIGN KEY (MaPhongBan) REFERENCES PhongBan(MaPhongBan)
);

-- Bảng ChamCong
CREATE TABLE ChamCong (
    MaChamCong VARCHAR(10) PRIMARY KEY,
    MaNhanVien VARCHAR(10) NOT NULL,
    ThoiGian VARCHAR(10) NOT NULL,
    NgayCong INT NOT NULL,
    SoNgayNghi INT NOT NULL,
    GioLamThem INT NOT NULL,
    FOREIGN KEY (MaNhanVien) REFERENCES NhanVien(MaNhanVien) ON DELETE CASCADE
);

-- Bảng Luong
CREATE TABLE Luong (
    MaLuong VARCHAR(10) PRIMARY KEY,
    MaNhanVien VARCHAR(10) NOT NULL,
    ThoiGian VARCHAR(10) NOT NULL,
    LuongCoBan INT NOT NULL,
    PhuCap INT NOT NULL,
    Thuong INT NOT NULL,
    Phat INT NOT NULL,
    Thue INT NOT NULL,
    ThucLanh INT NOT NULL,
    FOREIGN KEY (MaNhanVien) REFERENCES NhanVien(MaNhanVien) ON DELETE CASCADE
);

-- Bảng LuongPendingUpdate (Trung gian để lưu các thay đổi cần cập nhật MucLuong)
CREATE TABLE LuongPendingUpdate (
    MaNhanVien VARCHAR(10) PRIMARY KEY,
    NewLuongCoBan INT NOT NULL
);


-- Bảng TaiKhoan
CREATE TABLE TaiKhoan (
    MaNhanVien VARCHAR(10) PRIMARY KEY,
    Quyen VARCHAR(20) NOT NULL,
    FOREIGN KEY (MaNhanVien) REFERENCES NhanVien(MaNhanVien) ON DELETE CASCADE
);

-- Trigger tự động thêm bản ghi vào ChamCong sau khi thêm nhân viên
DELIMITER $$
CREATE TRIGGER trg_after_insert_nhanvien_chamcong
AFTER INSERT ON NhanVien
FOR EACH ROW
BEGIN
    INSERT INTO ChamCong (MaChamCong, MaNhanVien, ThoiGian, NgayCong, SoNgayNghi, GioLamThem)
    VALUES (CONCAT('CC', NEW.MaNhanVien), NEW.MaNhanVien, CURDATE(), 0, 0, 0);
END$$
DELIMITER ;

-- Trigger tự động thêm bản ghi vào Luong sau khi thêm nhân viên
DELIMITER $$
CREATE TRIGGER trg_after_insert_nhanvien_luong
AFTER INSERT ON NhanVien
FOR EACH ROW
BEGIN
    INSERT INTO Luong (MaLuong, MaNhanVien, ThoiGian, LuongCoBan, PhuCap, Thuong, Phat, Thue, ThucLanh)
    VALUES (CONCAT('L', NEW.MaNhanVien), NEW.MaNhanVien, CURDATE(), 0, 0, 0, 0, 0, 0);
END$$
DELIMITER ;

-- Trigger tự động thêm bản ghi vào TaiKhoan sau khi thêm nhân viên
DELIMITER $$
CREATE TRIGGER trg_after_insert_nhanvien_taikhoan
AFTER INSERT ON NhanVien
FOR EACH ROW
BEGIN
    INSERT INTO TaiKhoan (MaNhanVien, Quyen)
    VALUES (NEW.MaNhanVien, 'Nhân viên');
END$$
DELIMITER ;

-- Trigger cập nhật số lượng nhân viên trong PhongBan sau khi thêm nhân viên
DELIMITER $$
CREATE TRIGGER trg_after_insert_nhanvien_phongban
AFTER INSERT ON NhanVien
FOR EACH ROW
BEGIN
    UPDATE PhongBan
    SET SoLuongNhanVien = SoLuongNhanVien + 1
    WHERE MaPhongBan = NEW.MaPhongBan;
END$$
DELIMITER ;

-- Trigger cập nhật số lượng nhân viên trong PhongBan sau khi xóa nhân viên
DELIMITER $$
CREATE TRIGGER trg_after_delete_nhanvien_phongban
AFTER DELETE ON NhanVien
FOR EACH ROW
BEGIN
    UPDATE PhongBan
    SET SoLuongNhanVien = SoLuongNhanVien - 1
    WHERE MaPhongBan = OLD.MaPhongBan;
END$$
DELIMITER ;

-- Trigger cập nhật quyền trong TaiKhoan khi chức vụ nhân viên thay đổi
DELIMITER $$
CREATE TRIGGER trg_after_update_chucvu_taikhoan
AFTER UPDATE ON NhanVien
FOR EACH ROW
BEGIN
    UPDATE TaiKhoan
    SET Quyen = NEW.ChucVu
    WHERE MaNhanVien = NEW.MaNhanVien;
END$$
DELIMITER ;

-- Trigger thêm bản ghi vào bảng LuongPendingUpdate khi Luong được thêm hoặc cập nhật
DELIMITER $$
CREATE TRIGGER trg_after_insert_luong
AFTER INSERT ON Luong
FOR EACH ROW
BEGIN
    INSERT INTO LuongPendingUpdate (MaNhanVien, NewLuongCoBan)
    VALUES (NEW.MaNhanVien, NEW.LuongCoBan)
    ON DUPLICATE KEY UPDATE NewLuongCoBan = NEW.LuongCoBan;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_after_update_luong
AFTER UPDATE ON Luong
FOR EACH ROW
BEGIN
    INSERT INTO LuongPendingUpdate (MaNhanVien, NewLuongCoBan)
    VALUES (NEW.MaNhanVien, NEW.LuongCoBan)
    ON DUPLICATE KEY UPDATE NewLuongCoBan = NEW.LuongCoBan;
END$$
DELIMITER ;

-- Thực thi cập nhật MucLuong từ LuongPendingUpdate (có thể chạy thủ công hoặc định kỳ)
-- UPDATE NhanVien
-- JOIN LuongPendingUpdate ON NhanVien.MaNhanVien = LuongPendingUpdate.MaNhanVien
-- SET NhanVien.MucLuong = LuongPendingUpdate.NewLuongCoBan;
-- DELETE FROM LuongPendingUpdate;

USE qlnv6;

DROP TRIGGER IF EXISTS trg_after_insert_nhanvien_luong;


USE qlnv6;

DELIMITER $$

CREATE TRIGGER trg_after_insert_nhanvien_luong
AFTER INSERT ON NhanVien
FOR EACH ROW
BEGIN
    DECLARE mucLuong INT;

    -- Lấy giá trị MucLuong từ nhân viên mới thêm vào
    SET mucLuong = NEW.MucLuong;

    -- Thêm bản ghi vào bảng Luong với LuongCoBan = MucLuong của nhân viên
    INSERT INTO Luong (MaLuong, MaNhanVien, ThoiGian, LuongCoBan, PhuCap, Thuong, Phat, Thue, ThucLanh)
    VALUES (CONCAT('L', NEW.MaNhanVien), NEW.MaNhanVien, CURDATE(), mucLuong, 0, 0, 0, 0, 0);
END$$

DELIMITER ;



