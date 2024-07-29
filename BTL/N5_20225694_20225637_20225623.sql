-- create database
CREATE DATABASE elecdb_v1;
\c elecdb_v1

-- TABLE DEFINITION
-- Service (service_id, name)
-- Customer (customer_id, first_name, last_name, address, city, phone, email, identity_number, created_at, service_id)
-- Manager (manager_id, first_name, last_name, phone, email)
-- Meter (meter_id, customer_id, meter_number, installation_date, status)
-- MeterReading (reading_id, meter_id, reading_date, old_index, new_index, multiplier, consumption)
-- Price (price_id, service_id, start_date, tier_1, tier_2, tier_3, tier_4, tier_5, tier_6)
-- Invoice (invoice_id, customer_id, meter_id, service_id, invoice_date, due_date, vat, total_amount, status)
-- Payment (payment_id, invoice_id, payment_date, payment_method, status)

/**************************************************************************************************************************
**************************************************************************************************************************/

CREATE TABLE Service (
    service_id INT NOT NULL,
    name VARCHAR(50) NOT NULL,
    CONSTRAINT Service_pk PRIMARY KEY (service_id)
);

CREATE TABLE Customer (
    customer_id CHAR(10) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    address VARCHAR(100) NOT NULL,
	city VARCHAR(50) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(30) NOT NULL,
    identity_number VARCHAR(50) NOT NULL UNIQUE,
    created_at DATE,
	service_id INT NOT NULL,
    CONSTRAINT Customer_pk PRIMARY KEY (customer_id),
	CONSTRAINT Customer_fk_Service FOREIGN KEY (service_id) REFERENCES Service(service_id)
);

CREATE TABLE Manager (
    manager_id CHAR(10) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(30) NOT NULL,
    CONSTRAINT Manager_pk PRIMARY KEY (manager_id)
);

CREATE TABLE Meter (
    meter_id CHAR(10) NOT NULL,
    customer_id CHAR(10) NOT NULL,
    meter_number VARCHAR(50) NOT NULL,
    installation_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    CONSTRAINT Meter_pk PRIMARY KEY (meter_id),
    CONSTRAINT Meter_fk_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

CREATE TABLE MeterReading (
    reading_id CHAR(10) NOT NULL,
    meter_id CHAR(10) NOT NULL,
	service_id INT NOT NULL,
    reading_date DATE NOT NULL,
    old_index NUMERIC,
    new_index NUMERIC,
    multiplier FLOAT,
    consumption FLOAT,
    CONSTRAINT MeterReading_pk PRIMARY KEY (reading_id),
    CONSTRAINT MeterReading_fk_Meter FOREIGN KEY (meter_id) REFERENCES Meter(meter_id),
    CONSTRAINT MeterReading_fk_Service FOREIGN KEY (service_id) REFERENCES Service(service_id)
);

CREATE TABLE Price (
    price_id CHAR(10) NOT NULL,
    service_id INT NOT NULL,
    start_date DATE,
    tier_1 NUMERIC,
    tier_2 NUMERIC,
    tier_3 NUMERIC,
    tier_4 NUMERIC,
    tier_5 NUMERIC,
    tier_6 NUMERIC,
    CONSTRAINT Price_pk PRIMARY KEY (price_id),
    CONSTRAINT Price_fk_Service FOREIGN KEY (service_id) REFERENCES Service(service_id)
);

CREATE TABLE Invoice (
    invoice_id CHAR(10) NOT NULL,
    customer_id CHAR(10) NOT NULL,
    meter_id CHAR(10) NOT NULL,
    service_id INT NOT NULL,
    invoice_date DATE,
    due_date DATE,
    vat NUMERIC,
    consumption FLOAT,
    CONSTRAINT Invoice_pk PRIMARY KEY (invoice_id),
    CONSTRAINT Invoice_fk_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT Invoice_fk_Meter FOREIGN KEY (meter_id) REFERENCES Meter(meter_id),
    CONSTRAINT Invoice_fk_Service FOREIGN KEY (service_id) REFERENCES Service(service_id)
);

CREATE TABLE Payment (
    payment_id CHAR(10) NOT NULL,
    invoice_id CHAR(10) NOT NULL,
    payment_date DATE,
    payment_method VARCHAR(30),
    status VARCHAR(50) NOT NULL,
    CONSTRAINT Payments_pk PRIMARY KEY (payment_id),
    CONSTRAINT Payments_fk_Invoice FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id)
);

ALTER TABLE Invoice ADD COLUMN total_amount NUMERIC DEFAULT 0;

CREATE OR REPLACE FUNCTION calculate_total_amount()
RETURNS TRIGGER AS $$
DECLARE 
    v_tier_1 NUMERIC;
    v_tier_2 NUMERIC;
    v_tier_3 NUMERIC;
    v_tier_4 NUMERIC;
    v_tier_5 NUMERIC;
    v_tier_6 NUMERIC;
    v_consumption FLOAT;
    v_vat NUMERIC;
BEGIN
    SELECT tier_1, tier_2, tier_3, tier_4, tier_5, tier_6
    INTO v_tier_1, v_tier_2, v_tier_3, v_tier_4, v_tier_5, v_tier_6
    FROM Price
    WHERE service_id = NEW.service_id;
   
    v_consumption := NEW.consumption;
    v_vat := NEW.vat;
	
    IF v_consumption <= 50 THEN
        NEW.total_amount := v_consumption * v_tier_1 * (1 + v_vat);
    ELSIF v_consumption <= 100 THEN
        NEW.total_amount := (50 * v_tier_1 + (v_consumption - 50) * v_tier_2) * (1 + v_vat);
    ELSIF v_consumption <= 200 THEN
        NEW.total_amount := (50 * v_tier_1 + 50 * v_tier_2 + (v_consumption - 100) * v_tier_3) * (1 + v_vat);
    ELSIF v_consumption <= 300 THEN
        NEW.total_amount := (50 * v_tier_1 + 50 * v_tier_2 + 100 * v_tier_3 + (v_consumption - 200) * v_tier_4) * (1 + v_vat);
    ELSIF v_consumption <= 400 THEN
        NEW.total_amount := (50 * v_tier_1 + 50 * v_tier_2 + 100 * v_tier_3 + 100 * v_tier_4 + (v_consumption - 300) * v_tier_5) * (1 + v_vat);
    ELSE
        NEW.total_amount := (50 * v_tier_1 + 50 * v_tier_2 + 100 * v_tier_3 + 100 * v_tier_4 + 100 * v_tier_5 + (v_consumption - 400) * v_tier_6) * (1 + v_vat);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_calculate_total_amount
BEFORE INSERT ON Invoice
FOR EACH ROW
EXECUTE FUNCTION calculate_total_amount();

-- Tạo các Role
CREATE ROLE customer_role;
CREATE ROLE manager_role;

-- Gán quyền hạn cho khách hàng
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Customer TO customer_role;

CREATE USER customer_user WITH PASSWORD 'customer_password';
GRANT customer_role TO customer_user;

-- Gán quyền hạn cho quản lý
GRANT ALL PRIVILEGES ON TABLE Service TO manager_role;
GRANT ALL PRIVILEGES ON TABLE Customer TO manager_role;
GRANT ALL PRIVILEGES ON TABLE Meter TO manager_role;
GRANT ALL PRIVILEGES ON TABLE MeterReading TO manager_role;
GRANT ALL PRIVILEGES ON TABLE Price TO manager_role;
GRANT ALL PRIVILEGES ON TABLE Invoice TO manager_role;
GRANT ALL PRIVILEGES ON TABLE Payment TO manager_role;

CREATE USER manager_user WITH PASSWORD 'manager_password';
GRANT manager_role TO manager_user;

-- Index cho các khóa ngoại và các trường sử dụng thường xuyên trong điều kiện tìm kiếm
CREATE INDEX idx_customer_id ON Customer(customer_id);
CREATE INDEX idx_meter_id ON Meter(meter_id);
CREATE INDEX idx_service_id ON Service(service_id);

-- Index cho các trường tham gia vào các phép JOIN thường xuyên
CREATE INDEX idx_fk_meter_id ON MeterReading(meter_id);
CREATE INDEX idx_fk_service_id ON MeterReading(service_id);


/**************************************************************************************************************************
**************************************************************************************************************************/

-- Data
\encoding 'UTF8'

-- Service (service_id, name)
INSERT INTO Service (service_id, name) VALUES 
(1, 'Điện sinh hoạt'),
(2, 'Điện kinh doanh');


-- Customer
INSERT INTO Customer (customer_id, first_name, last_name, address, city, phone, email, identity_number, created_at, service_id) VALUES
('C1', 'Nguyễn', 'Văn Anh', '123 Đường Hoàng Văn Thụ', 'Hà Nội', '0987654321', 'nguyenvananh@example.com', '101234567890', '2020-01-01', 1),
('C2', 'Trần', 'Thị Bảo', '456 Đường Lê Lợi', 'Hồ Chí Minh', '0901234567', 'tranthibao@example.com', '102345678901', '2020-02-15', 2),
('C3', 'Lê', 'Văn Cường', '789 Đường Nguyễn Huệ', 'Đà Nẵng', '0978123456', 'levancuong@example.com', '103456789012', '2020-03-20', 1),
('C4', 'Phạm', 'Thị Diệu', '321 Đường Trần Hưng Đạo', 'Cần Thơ', '0912345678', 'phamthidieu@example.com', '104567890123', '2020-04-10', 2),
('C5', 'Nguyễn', 'Văn Đức', '654 Đường Lê Lai', 'Hải Phòng', '0965432109', 'nguyenvanduc@example.com', '105678901234', '2020-05-05', 1),
('C6', 'Bùi', 'Thị Êm', '987 Đường Ngô Quyền', 'Nam Định', '0987123456', 'buithiem@example.com', '106789021345', '2020-06-30', 2),
('C7', 'Võ', 'Văn Giang', '123 Đường Nguyễn Văn Linh', 'Hà Nội', '0909876543', 'vovang@example.com', '107890123489', '2020-07-12', 1),
('C8', 'Trần', 'Thị Hạnh', '456 Đường Lê Duẩn', 'Quảng Ninh', '0976543210', 'tranthihanh@example.com', '108901234567', '2020-08-25', 2),
('C9', 'Lê', 'Văn Hiếu', '789 Đường Nguyễn Huệ', 'Đà Nẵng', '0978123456', 'levanhieu@example.com', '109012345678', '2020-09-19', 1),
('C10', 'Phan', 'Thị Khánh', '123 Đường Hồ Tùng Mậu', 'Hà Tĩnh', '0901234567', 'phanthikhanh@example.com', '102156966791', '2020-10-03', 2),
('C11', 'Hoàng', 'Văn Long', '456 Đường Trần Hưng Đạo', 'Thanh Hóa', '0912345678', 'hoangvanlong@example.com', '101468619256', '2020-11-08', 1),
('C12', 'Mai', 'Thị Mến', '654 Đường Ngô Quyền', 'Hà Nội', '0987654321', 'maithimen@example.com', '103264914120', '2020-12-20', 2),
('C13', 'Lương', 'Văn Nghĩa', '987 Đường Lê Lợi', 'Quảng Bình', '0909876543', 'luongvannghia@example.com', '108945684123', '2021-01-02', 1),
('C14', 'Trần', 'Thị Oanh', '123 Đường Nguyễn Văn Linh', 'Hồ Chí Minh', '0901234567', 'tranthioanh@example.com', '105468135201', '2021-02-14', 2),
('C15', 'Ngô', 'Văn Phú', '456 Đường Trần Hưng Đạo', 'Thừa Thiên Huế', '0912345678', 'ngovanphu@example.com', '101245365899', '2021-03-30', 1),
('C16', 'Hồ', 'Văn Quân', '654 Đường Hoàng Văn Thụ', 'Quảng Nam', '0987654321', 'hovanquan@example.com', '100358135695', '2021-04-25', 2),
('C17', 'Đặng', 'Thị Rất', '789 Đường Lê Lợi', 'Quảng Ngãi', '0909876543', 'dangthirat@example.com', '108798456253', '2021-05-10', 1),
('C18', 'Nguyễn', 'Văn Sơn', '123 Đường Lê Duẩn', 'Bình Định', '0976543210', 'nguyenvanson@example.com', '103123456856', '2021-06-15', 2),
('C19', 'Trần', 'Thị Tâm', '456 Đường Nguyễn Huệ', 'Đà Nẵng', '0978123456', 'tranthitam@example.com', '104562589463', '2021-07-20', 1),
('C20', 'Lê', 'Văn Thành', '654 Đường Nguyễn Văn Linh', 'Nam Định', '0901234567', 'levanthanh@example.com', '102345228901', '2021-08-05', 2),
('C21', 'Phan', 'Thị Uyên', '987 Đường Trần Hưng Đạo', 'Khánh Hòa', '0912345678', 'phanthiuyen@example.com', '101235697856', '2021-09-19', 1),
('C22', 'Bùi', 'Văn Vượng', '123 Đường Hồ Tùng Mậu', 'Ninh Bình', '0909876543', 'buivanvuong@example.com', '107498621003', '2021-10-04', 2),
('C23', 'Võ', 'Thị Xinh', '456 Đường Ngô Quyền', 'Nam Định', '0987654321', 'vothixinh@example.com', '103468124223', '2021-11-08', 1),
('C24', 'Nguyễn', 'Văn Y', '789 Đường Nguyễn Huệ', 'Đà Nẵng', '0976543210', 'nguyenvany@example.com', '106789012345', '2021-12-20', 2),
('C25', 'Trần', 'Thị Zẹo', '123 Đường Lê Lợi', 'Hồ Chí Minh', '0901234567', 'tranthizeo@example.com', '107890123456', '2022-01-05', 1),
('C26', 'Lê', 'Văn An', '456 Đường Lê Duẩn', 'Đà Nẵng', '0978123456', 'levanan@example.com', '109851234567', '2022-02-14', 2),
('C27', 'Phạm', 'Thị Bình', '654 Đường Nguyễn Văn Linh', 'Hồ Chí Minh', '0909876543', 'phamthibinh@example.com', '107012345678', '2022-03-30', 1),
('C28', 'Hoàng', 'Văn Cảnh', '987 Đường Trần Hưng Đạo', 'Quảng Ninh', '0912345678', 'hoangvancanh@example.com', '100123456789', '2022-04-25', 2),
('C29', 'Mai', 'Thị Dung', '123 Đường Hoàng Văn Thụ', 'Hà Nội', '0987654321', 'maithidung@example.com', '101234585890', '2022-05-10', 1),
('C30', 'Nguyễn', 'Văn Em', '456 Đường Lê Lợi', 'Hồ Chí Minh', '0901234567', 'nguyenvanem@example.com', '102346278901', '2022-06-15', 2),
('C31', 'Đỗ', 'Thị Hà', '345 Đường Lê Lợi', 'Hà Nội', '0911223344', 'dothiha@example.com', '102567890123', '2022-07-10', 1),
('C32', 'Phạm', 'Văn Hải', '678 Đường Trần Hưng Đạo', 'Hồ Chí Minh', '0911223345', 'phamvanhai@example.com', '103678901234', '2022-08-15', 2),
('C33', 'Nguyễn', 'Thị Hương', '910 Đường Lê Duẩn', 'Đà Nẵng', '0911223346', 'nguyenthihuong@example.com', '104789012345', '2022-09-20', 1),
('C34', 'Trần', 'Văn Khoa', '112 Đường Nguyễn Huệ', 'Cần Thơ', '0911223347', 'tranvankhoa@example.com', '105890123456', '2022-10-25', 2),
('C35', 'Lê', 'Thị Lan', '345 Đường Hồ Tùng Mậu', 'Hải Phòng', '0911223348', 'lethilan@example.com', '106901234567', '2022-11-30', 1),
('C36', 'Bùi', 'Văn Lợi', '678 Đường Ngô Quyền', 'Nam Định', '0911223349', 'buivanloi@example.com', '107012851678', '2022-12-05', 2),
('C37', 'Võ', 'Thị Mai', '910 Đường Hoàng Văn Thụ', 'Hà Nội', '0911223350', 'vothimai@example.com', '108123456789', '2022-01-10', 1),
('C38', 'Trần', 'Văn Nam', '112 Đường Lê Lợi', 'Quảng Ninh', '0911223351', 'tranvannam@example.com', '109234567890', '2022-02-15', 2),
('C39', 'Lê', 'Thị Oanh', '345 Đường Trần Hưng Đạo', 'Đà Nẵng', '0911223352', 'lethioanh@example.com', '110345678901', '2022-03-20', 1),
('C40', 'Nguyễn', 'Văn Phúc', '678 Đường Nguyễn Văn Linh', 'Nam Định', '0911223353', 'nguyenvanphuc@example.com', '111456789012', '2022-04-25', 2),
('C41', 'Phạm', 'Thị Quỳnh', '910 Đường Hoàng Văn Thụ', 'Hồ Chí Minh', '0911223354', 'phamthiquynh@example.com', '112567890123', '2022-05-10', 1),
('C42', 'Đỗ', 'Văn Rạng', '112 Đường Lê Duẩn', 'Đà Nẵng', '0911223355', 'dovanrang@example.com', '113678901234', '2022-06-15', 2),
('C43', 'Nguyễn', 'Thị Sang', '345 Đường Nguyễn Huệ', 'Cần Thơ', '0911223356', 'nguyenthisang@example.com', '114789012345', '2022-07-20', 1),
('C44', 'Trần', 'Văn Tâm', '678 Đường Trần Hưng Đạo', 'Hà Nội', '0911223357', 'tranvantam@example.com', '115890123456', '2022-08-25', 2),
('C45', 'Lê', 'Thị Uyên', '910 Đường Ngô Quyền', 'Hải Phòng', '0911223358', 'lethiuyen@example.com', '116901234567', '2022-09-30', 1),
('C46', 'Bùi', 'Văn Vinh', '112 Đường Hồ Tùng Mậu', 'Nam Định', '0911223359', 'buivanvinh@example.com', '117012345678', '2022-10-05', 2),
('C47', 'Võ', 'Thị Xuyến', '345 Đường Lê Lợi', 'Hồ Chí Minh', '0911223360', 'vothixuyen@example.com', '118123456789', '2022-11-10', 1),
('C48', 'Nguyễn', 'Văn Yên', '678 Đường Nguyễn Văn Linh', 'Quảng Ninh', '0911223361', 'nguyenvanyen@example.com', '119234567890', '2022-12-15', 2),
('C49', 'Phạm', 'Thị Ánh', '910 Đường Trần Hưng Đạo', 'Đà Nẵng', '0911223362', 'phamthianh@example.com', '120345678901', '2022-01-10', 1),
('C50', 'Lê', 'Văn Bình', '112 Đường Lê Duẩn', 'Cần Thơ', '0911223363', 'levanbinh@example.com', '121456789012', '2022-02-15', 2),
('C51', 'Phạm', 'Thị Cẩm', '345 Đường Lê Lợi', 'Hà Nội', '0911234564', 'phamthicam@example.com', '122567890123', '2022-03-01', 1),
('C52', 'Nguyễn', 'Văn Dũng', '456 Đường Nguyễn Huệ', 'Đà Nẵng', '0911234565', 'nguyenvandung@example.com', '123678901234', '2022-04-15', 2),
('C53', 'Trần', 'Thị Diệu', '567 Đường Lê Lợi', 'Hồ Chí Minh', '0911234566', 'tranthidieu@example.com', '124789012345', '2022-05-05', 1),
('C54', 'Lê', 'Văn Đức', '678 Đường Hoàng Văn Thụ', 'Hải Phòng', '0911234567', 'levanduc@example.com', '125890123456', '2022-06-25', 2),
('C55', 'Phạm', 'Thị Đào', '789 Đường Lê Duẩn', 'Nam Định', '0911234568', 'phamthidao@example.com', '126901234567', '2022-07-10', 1),
('C56', 'Hoàng', 'Văn Minh', '890 Đường Nguyễn Văn Linh', 'Quảng Ninh', '0911234569', 'hoangvanminh@example.com', '127012345678', '2022-08-05', 2),
('C57', 'Vũ', 'Thị Ngọc', '123 Đường Trần Hưng Đạo', 'Hà Nội', '0911234570', 'vuthingoc@example.com', '128123456789', '2022-09-20', 1),
('C58', 'Trần', 'Văn An', '456 Đường Ngô Quyền', 'Đà Nẵng', '0911234571', 'tranvanan@example.com', '129234567890', '2022-10-15', 2),
('C59', 'Lê', 'Thị Bình', '789 Đường Hoàng Văn Thụ', 'Hồ Chí Minh', '0911234572', 'lethibinh@example.com', '130345678901', '2022-11-10', 1),
('C60', 'Nguyễn', 'Văn Châu', '890 Đường Lê Lợi', 'Hải Phòng', '0911234573', 'nguyenvanchau@example.com', '131456789012', '2022-12-05', 2),
('C61', 'Trần', 'Thị Diệu', '123 Đường Nguyễn Văn Linh', 'Nam Định', '0911234574', 'tranthidieu2@example.com', '132567890123', '2022-01-01', 1),
('C62', 'Phạm', 'Văn Đông', '456 Đường Trần Hưng Đạo', 'Quảng Ninh', '0911234575', 'phamvandong@example.com', '133678901234', '2022-02-20', 2),
('C63', 'Nguyễn', 'Thị Hoa', '789 Đường Nguyễn Huệ', 'Đà Nẵng', '0911234576', 'nguyenthihua@example.com', '134789012345', '2022-03-15', 1),
('C64', 'Lê', 'Văn Hiếu', '890 Đường Lê Duẩn', 'Hà Nội', '0911234577', 'levanhieu@example.com', '135890123456', '2022-04-10', 2),
('C65', 'Trần', 'Thị Linh', '123 Đường Hoàng Văn Thụ', 'Hồ Chí Minh', '0911234578', 'tranthilinh@example.com', '136901234567', '2022-05-25', 1),
('C66', 'Phạm', 'Văn Khánh', '456 Đường Lê Lợi', 'Hải Phòng', '0911234579', 'phamvankhanh@example.com', '137012345678', '2022-06-30', 2),
('C67', 'Nguyễn', 'Thị Lan', '789 Đường Ngô Quyền', 'Nam Định', '0911234580', 'nguyenthl@example.com', '138123456789', '2022-07-10', 1),
('C68', 'Lê', 'Văn Minh', '890 Đường Nguyễn Văn Linh', 'Quảng Ninh', '0911234581', 'levanminh@example.com', '139234567890', '2022-08-15', 2),
('C69', 'Trần', 'Thị Nga', '123 Đường Trần Hưng Đạo', 'Hà Nội', '0911234582', 'tranthinga@example.com', '140345678901', '2022-09-25', 1),
('C70', 'Phạm', 'Văn Phát', '456 Đường Ngô Quyền', 'Đà Nẵng', '0911234583', 'phamvanphat@example.com', '141456789012', '2022-10-10', 2),
('C71', 'Nguyễn', 'Thị Quý', '789 Đường Hoàng Văn Thụ', 'Hồ Chí Minh', '0911234584', 'nguyenthilqy@example.com', '142567890123', '2022-11-01', 1),
('C72', 'Lê', 'Văn Sơn', '890 Đường Lê Lợi', 'Hải Phòng', '0911234585', 'levanson@example.com', '143678901234', '2022-12-15', 2),
('C73', 'Trần', 'Thị Thanh', '123 Đường Nguyễn Văn Linh', 'Nam Định', '0911234586', 'tranthithanh@example.com', '144789012345', '2022-01-10', 1),
('C74', 'Phạm', 'Văn Tuấn', '456 Đường Trần Hưng Đạo', 'Quảng Ninh', '0911234587', 'phamvantuan@example.com', '145890123456', '2022-02-15', 2),
('C75', 'Nguyễn', 'Thị Vân', '789 Đường Nguyễn Huệ', 'Đà Nẵng', '0911234588', 'nguyenthivan@example.com', '146901234567', '2022-03-25', 1),
('C76', 'Lê', 'Văn Xuân', '890 Đường Lê Duẩn', 'Hà Nội', '0911234589', 'levanxuan@example.com', '147012345678', '2022-04-20', 2),
('C77', 'Trần', 'Thị Yến', '123 Đường Hoàng Văn Thụ', 'Hồ Chí Minh', '0911234590', 'tranthiyen@example.com', '148123456789', '2022-05-05', 1),
('C78', 'Phạm', 'Văn Cường', '456 Đường Lê Lợi', 'Hải Phòng', '0911234591', 'phamvancuong@example.com', '149234567890', '2022-06-30', 2),
('C79', 'Nguyễn', 'Thị Đào', '789 Đường Ngô Quyền', 'Nam Định', '0911234592', 'nguyenthidao@example.com', '150345678901', '2022-07-10', 1),
('C80', 'Lê', 'Văn Hiếu', '890 Đường Nguyễn Văn Linh', 'Quảng Ninh', '0911234593', 'levanhieu2@example.com', '151456789012', '2022-08-15', 2),
('C81', 'Trần', 'Thị Hương', '123 Đường Trần Hưng Đạo', 'Hà Nội', '0911234594', 'tranthihuong@example.com', '152567890123', '2022-09-25', 1),
('C82', 'Phạm', 'Văn Khánh', '456 Đường Ngô Quyền', 'Đà Nẵng', '0911234595', 'phamvankhanh2@example.com', '153678901234', '2022-10-10', 2),
('C83', 'Nguyễn', 'Thị Linh', '789 Đường Hoàng Văn Thụ', 'Hồ Chí Minh', '0911234596', 'nguyenthilinh@example.com', '154789012345', '2022-11-01', 1),
('C84', 'Lê', 'Văn Minh', '890 Đường Lê Lợi', 'Hải Phòng', '0911234597', 'levanminh2@example.com', '155890123456', '2022-12-15', 2),
('C85', 'Trần', 'Thị Ngọc', '123 Đường Nguyễn Văn Linh', 'Nam Định', '0911234598', 'tranthingoc@example.com', '156901234567', '2022-01-10', 1),
('C86', 'Phạm', 'Văn Phát', '456 Đường Trần Hưng Đạo', 'Quảng Ninh', '0911234599', 'phamvanphat2@example.com', '157012345678', '2022-02-15', 2),
('C87', 'Nguyễn', 'Thị Quý', '789 Đường Nguyễn Huệ', 'Đà Nẵng', '0911234600', 'nguyenthilqy2@example.com', '158123456789', '2022-03-25', 1),
('C88', 'Lê', 'Văn Sơn', '890 Đường Lê Duẩn', 'Hà Nội', '0911234601', 'levanson2@example.com', '159234567890', '2022-04-20', 2),
('C89', 'Trần', 'Thị Thanh', '123 Đường Hoàng Văn Thụ', 'Hồ Chí Minh', '0911234602', 'tranthithanh2@example.com', '160345678901', '2022-05-05', 1),
('C90', 'Phạm', 'Văn Tuấn', '456 Đường Lê Lợi', 'Hải Phòng', '0911234603', 'phamvantuan2@example.com', '161456789012', '2022-06-30', 2),
('C91', 'Nguyễn', 'Thị Vân', '789 Đường Ngô Quyền', 'Nam Định', '0911234604', 'nguyenthivan2@example.com', '162567890123', '2022-07-10', 1),
('C92', 'Lê', 'Văn Xuân', '890 Đường Nguyễn Văn Linh', 'Quảng Ninh', '0911234605', 'levanxuan2@example.com', '163678901234', '2022-08-15', 2),
('C93', 'Trần', 'Thị Yến', '123 Đường Trần Hưng Đạo', 'Hà Nội', '0911234606', 'tranthiyen2@example.com', '164789012345', '2022-09-25', 1),
('C94', 'Phạm', 'Văn Cường', '456 Đường Ngô Quyền', 'Đà Nẵng', '0911234607', 'phamvancuong2@example.com', '165890123456', '2022-10-10', 2),
('C95', 'Nguyễn', 'Thị Đào', '789 Đường Hoàng Văn Thụ', 'Hồ Chí Minh', '0911234608', 'nguyenthidao2@example.com', '166901234567', '2022-11-01', 1),
('C96', 'Lê', 'Văn Hiếu', '890 Đường Lê Lợi', 'Hải Phòng', '0911234609', 'levanhieu3@example.com', '167012345678', '2022-12-15', 2),
('C97', 'Trần', 'Thị Hương', '123 Đường Nguyễn Văn Linh', 'Nam Định', '0911234610', 'tranthihuong2@example.com', '168123456789', '2022-01-10', 1),
('C98', 'Phạm', 'Văn Khánh', '456 Đường Trần Hưng Đạo', 'Quảng Ninh', '0911234611', 'phamvankhanh3@example.com', '169234567890', '2022-02-15', 2),
('C99', 'Nguyễn', 'Thị Linh', '789 Đường Nguyễn Huệ', 'Đà Nẵng', '0911234612', 'nguyenthilinh2@example.com', '170345678901', '2022-03-25', 1),
('C100', 'Lê', 'Văn Minh', '890 Đường Lê Duẩn', 'Hà Nội', '0911234613', 'levanminh3@example.com', '171456789012', '2022-04-20', 2);


-- Manager
INSERT INTO Manager (manager_id, first_name, last_name, phone, email) VALUES
('M1', 'Trần', 'Phương Thúy', '0123453789', 'tranphngthuy@example.com'),
('M2', 'Trịnh', 'Kim Bích', '0985654321', 'trinhkimbich@example.com'),
('M3', 'Lê', 'Văn Lang', '0398765422', 'levanlang@example.com'),
('M4', 'Phạm', 'Diệu Linh', '0776543210', 'phamthidieu@example.com'),
('M5', 'Hoàng', 'Văn Thụ', '0365478901', 'hoangvanthu@example.com'),
('M6', 'Vũ', 'Thị Thúy Hòa', '0876543210', 'vuthuyhoa@example.com'),
('M7', 'Ngô', 'Yến Phương', '0956784321', 'ngoyenphuong@example.com'),
('M8', 'Đặng', 'Thị Thu Hà', '0345678901', 'dangthithuha@example.com'),
('M9', 'Nguyễn', 'Tú Hải', '0234567890', 'nguyentuhai@example.com'),
('M10', 'Trịnh', 'Văn Siêu', '0436789012', 'trinhvansieu@example.com');


-- Meter
INSERT INTO Meter (meter_id, customer_id, meter_number, installation_date, status) VALUES
('MT1', 'C1', 'MT45K9Q8', '2020-01-02', 'Active'),
('MT2', 'C2', 'M5Y8D0A2', '2020-02-16', 'Active'),
('MT3', 'C3', 'MZ4K6A0E', '2020-03-21', 'Active'),
('MT4', 'C4', '8Q7M3B6H', '2020-04-11', 'Active'),
('MT5', 'C5', '0T5R7M3I', '2020-05-06', 'Inactive'),
('MT6', 'C6', 'P8Y3B5L6', '2020-07-01', 'Active'),
('MT7', 'C7', 'V4L2M8N7', '2020-07-13', 'Active'),
('MT8', 'C8', '9O0P1Z3R', '2020-08-26', 'Active'),
('MT9', 'C9', '2R4Q1N6S', '2020-09-20', 'Active'),
('MT10', 'C10', '6T7S8V1Z', '2020-10-04', 'Active'),
('MT11', 'C11', 'S4U2C8Y9', '2020-11-09', 'Active'),
('MT12', 'C12', 'K2D5W7X3', '2020-12-21', 'Active'),
('MT13', 'C13', '3O7T5Z1Y', '2021-01-03', 'Active'),
('MT14', 'C14', 'Z5A1B7C3', '2021-02-15', 'Active'),
('MT15', 'C15', 'N0D5F8C1', '2021-03-31', 'Active'),
('MT16', 'C16', '2E4K6O9P', '2021-04-26', 'Active'),
('MT17', 'C17', '7W4M8G3H', '2021-05-11', 'Active'),
('MT18', 'C18', 'R5J9Z1I3', '2021-06-16', 'Active'),
('MT19', 'C19', 'L6F8K2M4', '2021-07-21', 'Active'),
('MT20', 'C20', 'B2N1M7I8', '2021-08-06', 'Active'),
('MT21', 'C21', 'Y3P6S9O5', '2021-09-20', 'Active'),
('MT22', 'C22', 'A5B9K6Q3', '2021-10-05', 'Active'),
('MT23', 'C23', 'C7V1W3T8', '2021-11-09', 'Active'),
('MT24', 'C24', 'G2U4F6X9', '2021-12-21', 'Active'),
('MT25', 'C25', 'Z0E1Y3W8', '2022-01-06', 'Active'),
('MT26', 'C26', 'K4N6U9Y2', '2022-02-15', 'Active'),
('MT27', 'C27', 'P3S6W9X5', '2022-03-31', 'Active'),
('MT28', 'C28', 'T9V1A3C2', '2022-04-26', 'Active'),
('MT29', 'C29', 'L6Q8F3E7', '2022-05-11', 'Active'),
('MT30', 'C30', 'R9Z1D2H3', '2022-06-16', 'Active'),
('MT31', 'C31', 'G1P4R7L9', '2022-07-11', 'Active'),
('MT32', 'C32', 'H3K7N2S5', '2022-08-16', 'Active'),
('MT33', 'C33', 'M6F2C8R1', '2022-09-21', 'Active'),
('MT34', 'C34', 'Q5L8Z3W7', '2022-10-26', 'Active'),
('MT35', 'C35', 'V2E4T9M6', '2022-12-01', 'Active'),
('MT36', 'C36', 'Y8S1P6K3', '2022-12-06', 'Active'),
('MT37', 'C37', 'B4N3M2Q7', '2022-01-11', 'Active'),
('MT38', 'C38', 'E6V1R4P9', '2022-02-16', 'Active'),
('MT39', 'C39', 'N9K2S5L3', '2022-03-21', 'Active'),
('MT40', 'C40', 'Z3W8M5T2', '2022-04-26', 'Active'),
('MT41', 'C41', 'K7P2L4G6', '2022-05-11', 'Active'),
('MT42', 'C42', 'R8M1S3T5', '2022-06-16', 'Active'),
('MT43', 'C43', 'C5L9Q2N7', '2022-07-21', 'Active'),
('MT44', 'C44', 'W1R6M4T3', '2022-08-26', 'Active'),
('MT45', 'C45', 'L8P2G3Q9', '2022-10-01', 'Active'),
('MT46', 'C46', 'T5N4S6R2', '2022-10-06', 'Active'),
('MT47', 'C47', 'P3M1Q5W8', '2022-11-11', 'Active'),
('MT48', 'C48', 'S7K4T2L3', '2022-12-16', 'Active'),
('MT49', 'C49', 'M9P1L8R4', '2022-01-11', 'Active'),
('MT50', 'C50', 'F6Q2W5G1', '2022-02-16', 'Active'),
('MT51', 'C51', 'R3W5Q8Z1', '2022-03-02', 'Active'),
('MT52', 'C52', 'K8M6P3T4', '2022-04-16', 'Inactive'),
('MT53', 'C53', 'L2Q1W6N7', '2022-05-06', 'Active'),
('MT54', 'C54', 'T5Y9B2K8', '2022-06-26', 'Active'),
('MT55', 'C55', 'P9R3K6M2', '2022-07-11', 'Inactive'),
('MT56', 'C56', 'W4N6T9Y3', '2022-08-06', 'Active'),
('MT57', 'C57', 'F1P8R3K6', '2022-09-21', 'Active'),
('MT58', 'C58', 'G2Y4K9P8', '2022-10-16', 'Inactive'),
('MT59', 'C59', 'S5T3N1Y2', '2022-11-11', 'Active'),
('MT60', 'C60', 'M6P9R2K3', '2022-12-06', 'Active'),
('MT61', 'C61', 'Z8L1Q6P3', '2022-01-02', 'Active'),
('MT62', 'C62', 'Q4K2W9N7', '2022-02-21', 'Inactive'),
('MT63', 'C63', 'R7P1M6K2', '2022-03-16', 'Active'),
('MT64', 'C64', 'Y2T8N3L5', '2022-04-11', 'Active'),
('MT65', 'C65', 'K9R1T5Y3', '2022-05-26', 'Active'),
('MT66', 'C66', 'F4Q7W2M9', '2022-06-30', 'Active'),
('MT67', 'C67', 'G1P6K8Y3', '2022-07-11', 'Inactive'),
('MT68', 'C68', 'S5N2L4T8', '2022-08-16', 'Active'),
('MT69', 'C69', 'M9K3P6R1', '2022-09-26', 'Active'),
('MT70', 'C70', 'Z2W8T1N3', '2022-10-11', 'Inactive'),
('MT71', 'C71', 'Q6K5R3P8', '2022-11-02', 'Active'),
('MT72', 'C72', 'R3T1Y6P9', '2022-12-16', 'Active'),
('MT73', 'C73', 'Y2N4L8K3', '2022-01-11', 'Inactive'),
('MT74', 'C74', 'K6P9R1M4', '2022-02-16', 'Active'),
('MT75', 'C75', 'F8Q3W6Y1', '2022-03-26', 'Active'),
('MT76', 'C76', 'G7P1K4M9', '2022-04-21', 'Inactive'),
('MT77', 'C77', 'S2T6N3Y8', '2022-05-06', 'Active'),
('MT78', 'C78', 'M9K8P1R2', '2022-06-28', 'Active'),
('MT79', 'C79', 'Z3W1T5N9', '2022-07-11', 'Active'),
('MT80', 'C80', 'Q9K2R1M6', '2022-08-16', 'Inactive'),
('MT81', 'C81', 'R6P8Y2K3', '2022-09-26', 'Active'),
('MT82', 'C82', 'Y4N2L6T9', '2022-10-11', 'Active'),
('MT83', 'C83', 'K8P1R5M2', '2022-11-02', 'Active'),
('MT84', 'C84', 'F3Q6W1Y9', '2022-12-16', 'Active'),
('MT85', 'C85', 'G8P2K1M7', '2022-01-11', 'Inactive'),
('MT86', 'C86', 'S3T9N2Y4', '2022-02-16', 'Active'),
('MT87', 'C87', 'M1K6P8R3', '2022-03-26', 'Active'),
('MT88', 'C88', 'Z9W2T1N4', '2022-04-21', 'Inactive'),
('MT89', 'C89', 'Q1K5R6P3', '2022-05-06', 'Active'),
('MT90', 'C90', 'R8P1Y6K2', '2022-09-25', 'Active'),
('MT91', 'C91', 'Y3N2L5T8', '2022-07-11', 'Active'),
('MT92', 'C92', 'K1P9R3M4', '2022-08-16', 'Active'),
('MT93', 'C93', 'F6Q2W8Y1', '2022-09-26', 'Inactive'),
('MT94', 'C94', 'G3P1K7M9', '2022-10-11', 'Active'),
('MT95', 'C95', 'S9T4N1Y2', '2022-11-02', 'Active'),
('MT96', 'C96', 'M8K1P4R6', '2022-12-16', 'Inactive'),
('MT97', 'C97', 'Z1W5T9N3', '2022-01-11', 'Active'),
('MT98', 'C98', 'Q2K3R1M8', '2022-02-16', 'Active'),
('MT99', 'C99', 'R1P8Y6K2', '2022-03-21', 'Active'),
('MT100', 'C100', 'Y6N3L4T9', '2022-04-21', 'Inactive');


-- MeterReading
INSERT INTO MeterReading (reading_id, meter_id, service_id, reading_date, old_index, new_index, multiplier, consumption) VALUES
('R1', 'MT1', 1, '2024-01-01', 1200, 1850, 1, (1850 - 1200) * 1),
('R2', 'MT2', 2, '2024-01-01', 800, 920, 1, (920 - 800) * 1),
('R3', 'MT3', 1, '2024-01-02', 950, 1450, 1, (1450 - 950) * 1),
('R4', 'MT4', 2, '2024-01-03', 2000, 2200, 1, (2200 - 2000) * 1),
('R5', 'MT5', 1, '2024-01-04', 1500, 1650, 1, (1650 - 1500) * 1),
('R6', 'MT6', 2, '2024-01-05', 1600, 2350, 1, (2350 - 1600) * 1),
('R7', 'MT7', 1, '2024-01-06', 2500, 2600, 1, (2600 - 2500) * 1),
('R8', 'MT8', 2, '2024-01-07', 1800, 1900, 1, (1900 - 1800) * 1),
('R9', 'MT9', 1, '2024-01-08', 700, 1030, 1, (1030 - 700) * 1),
('R10', 'MT10', 2, '2024-01-09', 1230, 1760, 1, (1760 - 1230) * 1),
('R11', 'MT11', 1, '2024-01-10', 2700, 3450, 1, (3450 - 2700) * 1),
('R12', 'MT12', 2, '2024-01-11', 2200, 2600, 1, (2600 - 2200) * 1),
('R13', 'MT13', 1, '2024-01-12', 2110, 2800, 1, (2800 - 2110) * 1),
('R14', 'MT14', 2, '2024-01-13', 3800, 4450, 1, (4450 - 3800) * 1),
('R15', 'MT15', 1, '2024-01-14', 3450, 4000, 1, (4000 - 3450) * 1),
('R16', 'MT16', 2, '2024-01-15', 900, 1430, 1, (1430 - 900) * 1),
('R17', 'MT17', 1, '2024-01-16', 1460, 1900, 1, (1900 - 1460) * 1),
('R18', 'MT18', 2, '2024-01-17', 2700, 3120, 1, (3120 - 2700) * 1),
('R19', 'MT19', 1, '2024-01-18', 1500, 1600, 1, (1600 - 1500) * 1),
('R20', 'MT20', 2, '2024-01-19', 2650, 3410, 1, (3410 - 2650) * 1),
('R21', 'MT21', 1, '2024-01-20', 2500, 2600, 1, (2600 - 2500) * 1),
('R22', 'MT22', 2, '2024-01-21', 1800, 1900, 1, (1900 - 1800) * 1),
('R23', 'MT23', 1, '2024-01-22', 2700, 3800, 1, (3800 - 2700) * 1),
('R24', 'MT24', 2, '2024-01-23', 1200, 1530, 1, (1530 - 1200) * 1),
('R25', 'MT25', 1, '2024-01-24', 2530, 3140, 1, (3140 - 2530) * 1),
('R26', 'MT26', 2, '2024-01-25', 2200, 2300, 1, (2300 - 2200) * 1),
('R27', 'MT27', 1, '2024-01-26', 856, 1630, 1, (1630 - 856) * 1),
('R28', 'MT28', 2, '2024-01-27', 1000, 1450, 1, (1450 - 1000) * 1),
('R29', 'MT29', 1, '2024-01-28', 3000, 3100, 1, (3100 - 3000) * 1),
('R30', 'MT30', 2, '2024-01-29', 940, 1400, 1, (1400 - 940) * 1),
('R31', 'MT31', 1, '2024-02-15', 1300, 1950, 1, (1950 - 1300) * 1),
('R32', 'MT32', 2, '2024-03-05', 1450, 1600, 1, (1600 - 1450) * 1),
('R33', 'MT33', 1, '2024-01-25', 1000, 1500, 1, (1500 - 1000) * 1),
('R34', 'MT34', 2, '2024-03-15', 1750, 2100, 1, (2100 - 1750) * 1),
('R35', 'MT35', 1, '2024-02-07', 800, 1200, 1, (1200 - 800) * 1),
('R36', 'MT36', 2, '2024-04-11', 950, 1300, 1, (1300 - 950) * 1),
('R37', 'MT37', 1, '2024-01-18', 2000, 2350, 1, (2350 - 2000) * 1),
('R38', 'MT38', 2, '2024-02-27', 1700, 1850, 1, (1850 - 1700) * 1),
('R39', 'MT39', 1, '2024-03-20', 1500, 1750, 1, (1750 - 1500) * 1),
('R40', 'MT40', 2, '2024-02-05', 2200, 2500, 1, (2500 - 2200) * 1),
('R41', 'MT41', 1, '2024-03-01', 2600, 2900, 1, (2900 - 2600) * 1),
('R42', 'MT42', 2, '2024-04-01', 1350, 1550, 1, (1550 - 1350) * 1),
('R43', 'MT43', 1, '2024-02-09', 1800, 2150, 1, (2150 - 1800) * 1),
('R44', 'MT44', 2, '2024-03-30', 1600, 1900, 1, (1900 - 1600) * 1),
('R45', 'MT45', 1, '2024-01-22', 2400, 2600, 1, (2600 - 2400) * 1),
('R46', 'MT46', 2, '2024-02-14', 1550, 1700, 1, (1700 - 1550) * 1),
('R47', 'MT47', 1, '2024-03-12', 1300, 1700, 1, (1700 - 1300) * 1),
('R48', 'MT48', 2, '2024-04-17', 1100, 1400, 1, (1400 - 1100) * 1),
('R49', 'MT49', 1, '2024-01-26', 2300, 2600, 1, (2600 - 2300) * 1),
('R50', 'MT50', 2, '2024-03-06', 900, 1150, 1, (1150 - 900) * 1),
('R51', 'MT51', 1, '2024-03-12', 1850, 2450, 1, (2450 - 1850) * 1),
('R52', 'MT52', 2, '2024-07-19', 920, 1050, 1, (1050 - 920) * 1),
('R53', 'MT53', 1, '2024-09-28', 1450, 1900, 1, (1900 - 1450) * 1),
('R54', 'MT54', 2, '2024-01-16', 2200, 2500, 1, (2500 - 2200) * 1),
('R55', 'MT55', 1, '2024-05-25', 1650, 1850, 1, (1850 - 1650) * 1),
('R56', 'MT56', 2, '2024-11-10', 2350, 3100, 1, (3100 - 2350) * 1),
('R57', 'MT57', 1, '2024-02-14', 2600, 2800, 1, (2800 - 2600) * 1),
('R58', 'MT58', 2, '2024-08-04', 1900, 2000, 1, (2000 - 1900) * 1),
('R59', 'MT59', 1, '2024-04-23', 1030, 1200, 1, (1200 - 1030) * 1),
('R60', 'MT60', 2, '2024-06-15', 1760, 1950, 1, (1950 - 1760) * 1),
('R61', 'MT61', 1, '2024-10-30', 3450, 4100, 1, (4100 - 3450) * 1),
('R62', 'MT62', 2, '2024-02-11', 2600, 2900, 1, (2900 - 2600) * 1),
('R63', 'MT63', 1, '2024-09-05', 2800, 3500, 1, (3500 - 2800) * 1),
('R64', 'MT64', 2, '2024-01-23', 4450, 4800, 1, (4800 - 4450) * 1),
('R65', 'MT65', 1, '2024-02-14', 4000, 4600, 1, (4600 - 4000) * 1),
('R66', 'MT66', 2, '2024-04-25', 1430, 1800, 1, (1800 - 1430) * 1),
('R67', 'MT67', 1, '2024-12-19', 1900, 2300, 1, (2300 - 1900) * 1),
('R68', 'MT68', 2, '2024-03-06', 3120, 3550, 1, (3550 - 3120) * 1),
('R69', 'MT69', 1, '2024-11-22', 1500, 1600, 1, (1600 - 1500) * 1),
('R70', 'MT70', 2, '2024-05-12', 2650, 3410, 1, (3410 - 2650) * 1),
('R71', 'MT71', 1, '2024-03-14', 2500, 2600, 1, (2600 - 2500) * 1),
('R72', 'MT72', 2, '2024-10-10', 1800, 1900, 1, (1900 - 1800) * 1),
('R73', 'MT73', 1, '2024-06-28', 2700, 3800, 1, (3800 - 2700) * 1),
('R74', 'MT74', 2, '2024-08-19', 1200, 1530, 1, (1530 - 1200) * 1),
('R75', 'MT75', 1, '2024-01-21', 2530, 3140, 1, (3140 - 2530) * 1),
('R76', 'MT76', 2, '2024-03-15', 2200, 2300, 1, (2300 - 2200) * 1),
('R77', 'MT77', 1, '2024-07-01', 856, 1630, 1, (1630 - 856) * 1),
('R78', 'MT78', 2, '2024-02-03', 1000, 1450, 1, (1450 - 1000) * 1),
('R79', 'MT79', 1, '2024-11-09', 3000, 3100, 1, (3100 - 3000) * 1),
('R80', 'MT80', 2, '2024-09-12', 940, 1400, 1, (1400 - 940) * 1),
('R81', 'MT81', 1, '2024-04-15', 1300, 1950, 1, (1950 - 1300) * 1),
('R82', 'MT82', 2, '2024-11-18', 1450, 1600, 1, (1600 - 1450) * 1),
('R83', 'MT83', 1, '2024-07-23', 1000, 1500, 1, (1500 - 1000) * 1),
('R84', 'MT84', 2, '2024-06-09', 1750, 2100, 1, (2100 - 1750) * 1),
('R85', 'MT85', 1, '2024-12-15', 800, 1200, 1, (1200 - 800) * 1),
('R86', 'MT86', 2, '2024-02-07', 950, 1300, 1, (1300 - 950) * 1),
('R87', 'MT87', 1, '2024-04-01', 2000, 2350, 1, (2350 - 2000) * 1),
('R88', 'MT88', 2, '2024-10-22', 1700, 1850, 1, (1850 - 1700) * 1),
('R89', 'MT89', 1, '2024-03-19', 1500, 1750, 1, (1750 - 1500) * 1),
('R90', 'MT90', 2, '2024-08-17', 2200, 2500, 1, (2500 - 2200) * 1),
('R91', 'MT91', 1, '2024-06-24', 2600, 2900, 1, (2900 - 2600) * 1),
('R92', 'MT92', 2, '2024-09-05', 1350, 1550, 1, (1550 - 1350) * 1),
('R93', 'MT93', 1, '2024-11-13', 1800, 2150, 1, (2150 - 1800) * 1),
('R94', 'MT94', 2, '2024-01-18', 1600, 1900, 1, (1900 - 1600) * 1),
('R95', 'MT95', 1, '2024-05-11', 2400, 2600, 1, (2600 - 2400) * 1),
('R96', 'MT96', 2, '2024-02-28', 1550, 1700, 1, (1700 - 1550) * 1),
('R97', 'MT97', 1, '2024-07-06', 1300, 1700, 1, (1700 - 1300) * 1),
('R98', 'MT98', 2, '2024-11-02', 1100, 1400, 1, (1400 - 1100) * 1),
('R99', 'MT99', 1, '2024-08-13', 2300, 2600, 1, (2600 - 2300) * 1),
('R100', 'MT100', 2, '2024-06-25', 900, 1150, 1, (1150 - 900) * 1);


-- Price
INSERT INTO Price (price_id, service_id, start_date, tier_1, tier_2, tier_3, tier_4, tier_5, tier_6) VALUES 
('P01', 1, '2023-11-09', 1.806, 1.866, 2.167, 2.729, 3.050, 3.151),
('P02', 2, '2023-11-09', 1.999, 2.103, 2.312, 2.897, 3.192, 3.374);


-- Invoice
INSERT INTO Invoice (invoice_id, customer_id, meter_id, service_id, invoice_date, due_date, consumption, vat) VALUES
('I1', 'C1', 'MT1', 1, '2024-01-02', '2024-02-02', (1850 - 1200) * 1, 0.1),
('I2', 'C2', 'MT2', 2, '2024-01-02', '2024-02-02', (920 - 800) * 1, 0.1),
('I3', 'C3', 'MT3', 1, '2024-01-03', '2024-02-03', (1450 - 950) * 1, 0.1),
('I4', 'C4', 'MT4', 2, '2024-01-04', '2024-02-04', (2200 - 2000) * 1, 0.1),
('I5', 'C5', 'MT5', 1, '2024-01-05', '2024-02-05', (1650 - 1500) * 1, 0.1),
('I6', 'C6', 'MT6', 2, '2024-01-06', '2024-02-06', (2350 - 1600) * 1, 0.1),
('I7', 'C7', 'MT7', 1, '2024-01-07', '2024-02-07', (2600 - 2500) * 1, 0.1),
('I8', 'C8', 'MT8', 2, '2024-01-08', '2024-02-08', (1900 - 1800) * 1, 0.1),
('I9', 'C9', 'MT9', 1, '2024-01-09', '2024-02-09', (1030 - 700) * 1, 0.1),
('I10', 'C10', 'MT10', 2, '2024-01-10', '2024-02-10', (1760 - 1230) * 1, 0.1),
('I11', 'C11', 'MT11', 1, '2024-01-11', '2024-02-11', (3450 - 2700) * 1, 0.1),
('I12', 'C12', 'MT12', 2, '2024-01-12', '2024-02-12', (2600 - 2200) * 1, 0.1),
('I13', 'C13', 'MT13', 1, '2024-01-13', '2024-02-13', (2800 - 2110) * 1, 0.1),
('I14', 'C14', 'MT14', 2, '2024-01-14', '2024-02-14', (4450 - 3800) * 1, 0.1),
('I15', 'C15', 'MT15', 1, '2024-01-15', '2024-02-15', (4000 - 3450) * 1, 0.1),
('I16', 'C16', 'MT16', 2, '2024-01-16', '2024-02-16', (1430 - 900) * 1, 0.1),
('I17', 'C17', 'MT17', 1, '2024-01-17', '2024-02-17', (1900 - 1460) * 1, 0.1),
('I18', 'C18', 'MT18', 2, '2024-01-18', '2024-02-18', (3120 - 2700) * 1, 0.1),
('I19', 'C19', 'MT19', 1, '2024-01-19', '2024-02-19', (1600 - 1500) * 1, 0.1),
('I20', 'C20', 'MT20', 2, '2024-01-20', '2024-02-20', (3410 - 2650) * 1, 0.1),
('I21', 'C21', 'MT21', 1, '2024-01-21', '2024-02-21', (2600 - 2500) * 1, 0.1),
('I22', 'C22', 'MT22', 2, '2024-01-22', '2024-02-22', (1900 - 1800) * 1, 0.1),
('I23', 'C23', 'MT23', 1, '2024-01-23', '2024-02-23', (3800 - 2700) * 1, 0.1),
('I24', 'C24', 'MT24', 2, '2024-01-24', '2024-02-24', (1530 - 1200) * 1, 0.1),
('I25', 'C25', 'MT25', 1, '2024-01-25', '2024-02-25', (3140 - 2530) * 1, 0.1),
('I26', 'C26', 'MT26', 2, '2024-01-26', '2024-02-26', (2300 - 2200) * 1, 0.1),
('I27', 'C27', 'MT27', 1, '2024-01-27', '2024-02-27', (1630 - 856) * 1, 0.1),
('I28', 'C28', 'MT28', 2, '2024-01-28', '2024-02-28', (1450 - 1000) * 1, 0.1),
('I29', 'C29', 'MT29', 1, '2024-01-29', '2024-03-01', (3100 - 3000) * 1, 0.1),
('I30', 'C30', 'MT30', 2, '2024-01-30', '2024-03-01', (1400 - 940) * 1, 0.1),
('I31', 'C31', 'MT31', 1, '2024-02-16', '2024-03-16', (1950 - 1300) * 1, 0.1),
('I32', 'C32', 'MT32', 2, '2024-03-06', '2024-04-06', (1600 - 1450) * 1, 0.1),
('I33', 'C33', 'MT33', 1, '2024-01-26', '2024-02-26', (1500 - 1000) * 1, 0.1),
('I34', 'C34', 'MT34', 2, '2024-03-16', '2024-04-16', (2100 - 1750) * 1, 0.1),
('I35', 'C35', 'MT35', 1, '2024-02-08', '2024-03-08', (1200 - 800) * 1, 0.1),
('I36', 'C36', 'MT36', 2, '2024-04-12', '2024-05-12', (1300 - 950) * 1, 0.1),
('I37', 'C37', 'MT37', 1, '2024-01-19', '2024-02-19', (2350 - 2000) * 1, 0.1),
('I38', 'C38', 'MT38', 2, '2024-02-28', '2024-03-28', (1850 - 1700) * 1, 0.1),
('I39', 'C39', 'MT39', 1, '2024-03-21', '2024-04-21', (1750 - 1500) * 1, 0.1),
('I40', 'C40', 'MT40', 2, '2024-02-06', '2024-03-06', (2500 - 2200) * 1, 0.1),
('I41', 'C41', 'MT41', 1, '2024-03-02', '2024-04-02', (2900 - 2600) * 1, 0.1),
('I42', 'C42', 'MT42', 2, '2024-04-02', '2024-05-02', (1550 - 1350) * 1, 0.1),
('I43', 'C43', 'MT43', 1, '2024-02-10', '2024-03-10', (2150 - 1800) * 1, 0.1),
('I44', 'C44', 'MT44', 2, '2024-03-31', '2024-04-30', (1900 - 1600) * 1, 0.1),
('I45', 'C45', 'MT45', 1, '2024-01-23', '2024-02-23', (2600 - 2400) * 1, 0.1),
('I46', 'C46', 'MT46', 2, '2024-02-15', '2024-03-15', (1700 - 1550) * 1, 0.1),
('I47', 'C47', 'MT47', 1, '2024-03-13', '2024-04-13', (1700 - 1300) * 1, 0.1),
('I48', 'C48', 'MT48', 2, '2024-04-18', '2024-05-18', (1400 - 1100) * 1, 0.1),
('I49', 'C49', 'MT49', 1, '2024-01-27', '2024-02-27', (2600 - 2300) * 1, 0.1),
('I50', 'C50', 'MT50', 2, '2024-03-07', '2024-04-07', (1150 - 900) * 1, 0.1),
('I51', 'C51', 'MT51', 1, '2024-03-13', '2024-04-13', (2450 - 1850) * 1, 0.1),
('I52', 'C52', 'MT52', 2, '2024-07-20', '2024-08-20', (1050 - 920) * 1, 0.1),
('I53', 'C53', 'MT53', 1, '2024-09-29', '2024-10-29', (1900 - 1450) * 1, 0.1),
('I54', 'C54', 'MT54', 2, '2024-01-17', '2024-02-17', (2500 - 2200) * 1, 0.1),
('I55', 'C55', 'MT55', 1, '2024-05-26', '2024-06-26', (1850 - 1650) * 1, 0.1),
('I56', 'C56', 'MT56', 2, '2024-11-11', '2024-12-11', (3100 - 2350) * 1, 0.1),
('I57', 'C57', 'MT57', 1, '2024-02-15', '2024-03-15', (2800 - 2600) * 1, 0.1),
('I58', 'C58', 'MT58', 2, '2024-08-05', '2024-09-05', (2000 - 1900) * 1, 0.1),
('I59', 'C59', 'MT59', 1, '2024-04-24', '2024-05-24', (1200 - 1030) * 1, 0.1),
('I60', 'C60', 'MT60', 2, '2024-06-16', '2024-07-16', (1950 - 1760) * 1, 0.1),
('I61', 'C61', 'MT61', 1, '2024-10-31', '2024-11-30', (4100 - 3450) * 1, 0.1),
('I62', 'C62', 'MT62', 2, '2024-02-12', '2024-03-12', (2900 - 2600) * 1, 0.1),
('I63', 'C63', 'MT63', 1, '2024-09-06', '2024-10-06', (3500 - 2800) * 1, 0.1),
('I64', 'C64', 'MT64', 2, '2024-01-24', '2024-02-24', (4800 - 4450) * 1, 0.1),
('I65', 'C65', 'MT65', 1, '2024-02-15', '2024-03-15', (4600 - 4000) * 1, 0.1),
('I66', 'C66', 'MT66', 2, '2024-04-26', '2024-05-26', (1800 - 1430) * 1, 0.1),
('I67', 'C67', 'MT67', 1, '2024-12-20', '2025-01-20', (2300 - 1900) * 1, 0.1),
('I68', 'C68', 'MT68', 2, '2024-03-07', '2024-04-07', (3550 - 3120) * 1, 0.1),
('I69', 'C69', 'MT69', 1, '2024-11-23', '2024-12-23', (1600 - 1500) * 1, 0.1),
('I70', 'C70', 'MT70', 2, '2024-05-13', '2024-06-13', (3410 - 2650) * 1, 0.1),
('I71', 'C71', 'MT71', 1, '2024-03-15', '2024-04-15', (2600 - 2500) * 1, 0.1),
('I72', 'C72', 'MT72', 2, '2024-10-11', '2024-11-11', (1900 - 1800) * 1, 0.1),
('I73', 'C73', 'MT73', 1, '2024-06-29', '2024-07-29', (3800 - 2700) * 1, 0.1),
('I74', 'C74', 'MT74', 2, '2024-08-20', '2024-09-20', (1530 - 1200) * 1, 0.1),
('I75', 'C75', 'MT75', 1, '2024-01-22', '2024-02-22', (3140 - 2530) * 1, 0.1),
('I76', 'C76', 'MT76', 2, '2024-03-16', '2024-04-16', (2300 - 2200) * 1, 0.1),
('I77', 'C77', 'MT77', 1, '2024-07-02', '2024-08-02', (1630 - 856) * 1, 0.1),
('I78', 'C78', 'MT78', 2, '2024-02-04', '2024-03-04', (1450 - 1000) * 1, 0.1),
('I79', 'C79', 'MT79', 1, '2024-11-10', '2024-12-10', (3100 - 3000) * 1, 0.1),
('I80', 'C80', 'MT80', 2, '2024-09-13', '2024-10-13', (1400 - 940) * 1, 0.1),
('I81', 'C81', 'MT81', 1, '2024-04-16', '2024-05-16', (1950 - 1300) * 1, 0.1),
('I82', 'C82', 'MT82', 2, '2024-11-19', '2024-12-19', (1600 - 1450) * 1, 0.1),
('I83', 'C83', 'MT83', 1, '2024-07-24', '2024-08-24', (1500 - 1000) * 1, 0.1),
('I84', 'C84', 'MT84', 2, '2024-06-10', '2024-07-10', (2100 - 1750) * 1, 0.1),
('I85', 'C85', 'MT85', 1, '2024-12-16', '2025-01-16', (1200 - 800) * 1, 0.1),
('I86', 'C86', 'MT86', 2, '2024-02-08', '2024-03-08', (1300 - 950) * 1, 0.1),
('I87', 'C87', 'MT87', 1, '2024-04-02', '2024-05-02', (2350 - 2000) * 1, 0.1),
('I88', 'C88', 'MT88', 2, '2024-10-23', '2024-11-23', (1850 - 1700) * 1, 0.1),
('I89', 'C89', 'MT89', 1, '2024-03-20', '2024-04-20', (1750 - 1500) * 1, 0.1),
('I90', 'C90', 'MT90', 2, '2024-08-18', '2024-09-18', (2500 - 2200) * 1, 0.1),
('I91', 'C91', 'MT91', 1, '2024-06-25', '2024-07-25', (2900 - 2600) * 1, 0.1),
('I92', 'C92', 'MT92', 2, '2024-09-06', '2024-10-06', (1550 - 1350) * 1, 0.1),
('I93', 'C93', 'MT93', 1, '2024-11-14', '2024-12-14', (2150 - 1800) * 1, 0.1),
('I94', 'C94', 'MT94', 2, '2024-01-19', '2024-02-19', (1900 - 1600) * 1, 0.1),
('I95', 'C95', 'MT95', 1, '2024-08-16', '2024-09-16', (2600 - 2400) * 1, 0.1),
('I96', 'C96', 'MT96', 2, '2024-08-03', '2024-09-03', (1700 - 1550) * 1, 0.1),
('I97', 'C97', 'MT97', 1, '2024-06-07', '2024-07-07', (1700 - 1300) * 1, 0.1),
('I98', 'C98', 'MT98', 2, '2024-08-08', '2024-09-08', (1400 - 1100) * 1, 0.1),
('I99', 'C99', 'MT99', 1, '2024-07-07', '2024-08-07', (2600 - 2300) * 1, 0.1),
('I100', 'C100', 'MT100', 2, '2024-08-08', '2024-09-08', (1150 - 900) * 1, 0.1);


-- Payment
INSERT INTO Payment (payment_id, invoice_id, payment_date, payment_method, status) VALUES
('P1', 'I1', '2024-01-15', 'Trực tuyến', 'Đã thanh toán'),
('P2', 'I2', NULL, NULL, 'Chưa thanh toán'),
('P3', 'I3', '2024-01-17', 'Trực tuyến', 'Đã thanh toán'),
('P4', 'I4', '2024-02-18', 'Trực tiếp', 'Đã thanh toán'),
('P5', 'I5', '2024-05-19', 'Trực tuyến', 'Đã thanh toán'),
('P6', 'I6', '2024-01-20', 'Trực tiếp', 'Đã thanh toán'),
('P7', 'I7', NULL, NULL, 'Chưa thanh toán'),
('P8', 'I8', '2024-03-22', 'Trực tiếp', 'Đã thanh toán'),
('P9', 'I9', NULL, NULL, 'Chưa thanh toán'),
('P10', 'I10', '2024-01-24', 'Trực tiếp', 'Đã thanh toán'),
('P11', 'I11', NULL, NULL, 'Chưa thanh toán'),
('P12', 'I12', '2024-01-11', 'Trực tiếp', 'Đã thanh toán'),
('P13', 'I13', NULL, NULL, 'Chưa thanh toán'),
('P14', 'I14', '2024-02-12', 'Trực tiếp', 'Đã thanh toán'),
('P15', 'I15', NULL, NULL, 'Chưa thanh toán'),
('P16', 'I16', '2024-01-30', 'Trực tiếp', 'Đã thanh toán'),
('P17', 'I17', NULL, NULL, 'Chưa thanh toán'),
('P18', 'I18', NULL, 'Trực tiếp', 'Chưa thanh toán'),
('P19', 'I19', NULL, NULL, 'Chưa thanh toán'),
('P20', 'I20', NULL, NULL, 'Chưa thanh toán'),
('P21', 'I21', NULL, NULL, 'Chưa thanh toán'),
('P22', 'I22', '2024-02-05', 'Trực tiếp', 'Đã thanh toán'),
('P23', 'I23', NULL, NULL, 'Chưa thanh toán'),
('P24', 'I24', '2024-03-07', 'Trực tiếp', 'Đã thanh toán'),
('P25', 'I25', NULL, NULL, 'Chưa thanh toán'),
('P26', 'I26', '2024-02-09', 'Trực tiếp', 'Đã thanh toán'),
('P27', 'I27', NULL, NULL, 'Chưa thanh toán'),
('P28', 'I28', '2024-02-11', 'Trực tiếp', 'Đã thanh toán'),
('P29', 'I29', NULL, NULL, 'Chưa thanh toán'),
('P30', 'I30', '2024-04-13', 'Trực tiếp', 'Đã thanh toán'),
('P31', 'I31', NULL, NULL, 'Chưa thanh toán'),
('P32', 'I32', '2024-04-15', 'Trực tiếp', 'Đã thanh toán'),
('P33', 'I33', NULL, NULL, 'Chưa thanh toán'),
('P34', 'I34', '2024-04-17', 'Trực tiếp', 'Đã thanh toán'),
('P35', 'I35', '2024-03-18', 'Trực tuyến', 'Đã thanh toán'),
('P36', 'I36', '2024-05-19', 'Trực tiếp', 'Đã thanh toán'),
('P37', 'I37', NULL, NULL, 'Chưa thanh toán'),
('P38', 'I38', '2024-05-21', 'Trực tiếp', 'Đã thanh toán'),
('P39', 'I39', NULL, NULL, 'Chưa thanh toán'),
('P40', 'I40', '2024-06-23', 'Trực tiếp', 'Đã thanh toán'),
('P41', 'I41', NULL, NULL, 'Chưa thanh toán'),
('P42', 'I42', NULL, NULL, 'Chưa thanh toán'),
('P43', 'I43', NULL, NULL, 'Chưa thanh toán'),
('P44', 'I44', '2024-06-27', 'Trực tiếp', 'Đã thanh toán'),
('P45', 'I45', NULL, NULL, 'Chưa thanh toán'),
('P46', 'I46', '2024-02-29', 'Trực tiếp', 'Đã thanh toán'),
('P47', 'I47', NULL, NULL, 'Chưa thanh toán'),
('P48', 'I48', '2024-05-01', 'Trực tiếp', 'Đã thanh toán'),
('P49', 'I49', NULL, NULL, 'Chưa thanh toán'),
('P50', 'I50', NULL, 'Trực tiếp', 'Chưa thanh toán'),
('P51', 'I51', NULL, NULL, 'Chưa thanh toán'),
('P52', 'I52', '2024-08-03', 'Trực tiếp', 'Đã thanh toán'),
('P53', 'I53', NULL, NULL, 'Chưa thanh toán'),
('P54', 'I54', '2024-08-05', 'Trực tiếp', 'Đã thanh toán'),
('P55', 'I55', NULL, NULL, 'Chưa thanh toán'),
('P56', 'I56', '2024-12-07', 'Trực tiếp', 'Đã thanh toán'),
('P57', 'I57', NULL, NULL, 'Chưa thanh toán'),
('P58', 'I58', '2024-03-09', 'Trực tiếp', 'Đã thanh toán'),
('P59', 'I59', NULL, NULL, 'Chưa thanh toán'),
('P60', 'I60', '2024-07-11', 'Trực tiếp', 'Đã thanh toán'),
('P61', 'I61', NULL, NULL, 'Chưa thanh toán'),
('P62', 'I62', '2024-03-13', 'Trực tiếp', 'Đã thanh toán'),
('P63', 'I63', NULL, NULL, 'Chưa thanh toán'),
('P64', 'I64', '2024-02-15', 'Trực tiếp', 'Đã thanh toán'),
('P65', 'I65', NULL, NULL, 'Chưa thanh toán'),
('P66', 'I66', '2024-05-17', 'Trực tiếp', 'Đã thanh toán'),
('P67', 'I67', NULL, NULL, 'Chưa thanh toán'),
('P68', 'I68', '2024-04-19', 'Trực tiếp', 'Đã thanh toán'),
('P69', 'I69', NULL, NULL, 'Chưa thanh toán'),
('P70', 'I70', '2024-12-21', 'Trực tiếp', 'Đã thanh toán'),
('P71', 'I71', NULL, NULL, 'Chưa thanh toán'),
('P72', 'I72', '2024-06-23', 'Trực tiếp', 'Đã thanh toán'),
('P73', 'I73', NULL, NULL, 'Chưa thanh toán'),
('P74', 'I74', '2024-09-25', 'Trực tiếp', 'Đã thanh toán'),
('P75', 'I75', NULL, NULL, 'Chưa thanh toán'),
('P76', 'I76', '2024-03-27', 'Trực tiếp', 'Đã thanh toán'),
('P77', 'I77', NULL, NULL, 'Chưa thanh toán'),
('P78', 'I78', '2024-04-29', 'Trực tiếp', 'Đã thanh toán'),
('P79', 'I79', NULL, NULL, 'Chưa thanh toán'),
('P80', 'I80', '2024-10-31', 'Trực tiếp', 'Đã thanh toán'),
('P81', 'I81', NULL, NULL, 'Chưa thanh toán'),
('P82', 'I82', '2024-12-02', 'Trực tiếp', 'Đã thanh toán'),
('P83', 'I83', NULL, NULL, 'Chưa thanh toán'),
('P84', 'I84', '2024-08-04', 'Trực tiếp', 'Đã thanh toán'),
('P85', 'I85', NULL, NULL, 'Chưa thanh toán'),
('P86', 'I86', '2024-08-06', 'Trực tiếp', 'Đã thanh toán'),
('P87', 'I87', NULL, NULL, 'Chưa thanh toán'),
('P88', 'I88', '2024-11-08', 'Trực tiếp', 'Đã thanh toán'),
('P89', 'I89', NULL, NULL, 'Chưa thanh toán'),
('P90', 'I90', '2024-09-10', 'Trực tiếp', 'Đã thanh toán'),
('P91', 'I91', NULL, NULL, 'Chưa thanh toán'),
('P92', 'I92', '2024-09-12', 'Trực tiếp', 'Đã thanh toán'),
('P93', 'I93', NULL, NULL, 'Chưa thanh toán'),
('P94', 'I94', '2024-04-14', 'Trực tiếp', 'Đã thanh toán'),
('P95', 'I95', NULL, NULL, 'Chưa thanh toán'),
('P96', 'I96', '2024-08-16', 'Trực tiếp', 'Đã thanh toán'),
('P97', 'I97', NULL, NULL, 'Chưa thanh toán'),
('P98', 'I98', '2024-08-18', 'Trực tiếp', 'Đã thanh toán'),
('P99', 'I99', NULL, NULL, 'Chưa thanh toán'),
('P100', 'I100', '2024-08-20', 'Trực tiếp', 'Đã thanh toán');