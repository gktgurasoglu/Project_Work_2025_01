SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_schema = 'project' 
    AND table_name = 'games_payments'; -- dosyaların sütun adlarını ve veri türlerini inceliyoruz.

SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_schema = 'project' 
    AND table_name = 'games_paid_users'; -- dosyaların sütun adlarını ve veri türlerini inceilyoruz.
-- Dönüştürmemiz gereken herhangi bir veri türü yok

SELECT 
    COUNT(*) AS total_rows,
    COUNT(user_id) AS id_non_null_row,
    COUNT(game_name) AS game_non_null_row,
    COUNT(payment_date) AS date_non_null_row,
    COUNT(revenue_amount_usd) AS amount_non_null_row
FROM 
    project.games_payments;  -- 3026 satır var, hiç null değer yok.
    
SELECT 
    COUNT(*) AS total_rows,
    COUNT(user_id) AS id_non_null_row,
    COUNT(game_name) AS game_non_null_row,
    COUNT(language) AS language_non_null_row,
    COUNT(has_older_device_model) AS device_non_null_row,
    COUNT(age) AS age_non_null_row
FROM 
    project.games_paid_users;  -- 383 satır var, hiç null değer yok.
-- Silmemiz gereken ya da belli şekillerde doldurmamız gereken hücre yok.
    
SELECT 
    MIN(revenue_amount_usd) AS min_value,
    MAX(revenue_amount_usd) AS max_value,
    AVG(revenue_amount_usd) AS avg_value,
    STDDEV(revenue_amount_usd) AS std_dev
FROM 
    project.games_payments; -- gelir verisi hakkında fikir sahibi oluyoruz. Ort 21 dolar ve st.sp gösteriyor ki dağılımın yoğunluğu neredeyse min tutarı kapsıyor.

SELECT 
    MIN(age) AS min_value,
    MAX(age) AS max_value,
    AVG(age) AS avg_value,
    STDDEV(age) AS std_dev
FROM 
    project.games_paid_users; -- yaş dağılımı hakkında fikir sahibi oluyoruz. St.sp biraz yüksek, yani yaş dağılımı 16-30 arasında yoğunlaşıyor.

SELECT 
    MIN(payment_date) AS first_date,
    MAX(payment_date) AS last_date
FROM 
    project.games_payments; -- Tüm işlemler 2022 yılı içinde gerçekleşmiş, Mart ayında başlamış ve Aralık sonunda kapanmış.
-- Yaş hesaplaması kontrolü için detay düşünmemize gerek kalmadı. (verilerin doğruluk kalitesi bakımından)

SELECT 
    count(distinct user_id) as benzersiz_kullanıcı
FROM 
    project.games_payments; -- Benzersiz kullanıcı sayısını tespit edip, paid_users dosyasıyla karşılaştırıyoruz; aynı sayıda olduğunu tespit ediyoruz: 383. Ayrıca her kullanıcının sadece 1 oyun kullandığını anlıyoruz.
-- İki dosyasının kullanıcı id'lerinin aynı olduğunu ve farklılık olmadığını anlıyoruz.
    
select  game_name,
        DATE_TRUNC('month', payment_date)::DATE AS payment_month,
        SUM(revenue_amount_usd) AS total_payment
    FROM project.games_payments
    GROUP BY game_name, DATE_TRUNC('month', payment_date)
    order by game_name, DATE_TRUNC('month', payment_date) -- oyunların aylık gelirlerini inceliyoruz. Oyun1'in 3 aylık (çok yeni), Oyun2'nin 6 aylık (11inci ay verisi yok!) olduğunu tespit ediyoruz.
-- Her kullanıcı sadece 1 oyun oynamış ve game1 çok yeni bir oyun (3 aylık) - bu kapsamda game1/game/2 için game3de reklam yapılabilir, ve karşılaştırma için game3 ün ilk 3/6 aylık verisi talep edeilebilir.
-- Karar verirken game1 ve game2 yi uygulamadan kaldırma fikrini tekrar gözden geçirmemize ve farklı tekliflerde bulunmamıza sebep olabilir.
    
SELECT
        user_id,
        game_name,
        language,
        has_older_device_model,
        age,
        generate_series(
            (SELECT MIN(DATE_TRUNC('month', payment_date)) FROM project.games_payments),
            (SELECT MAX(DATE_TRUNC('month', payment_date)) FROM project.games_payments),
            INTERVAL '1 month')::DATE AS payment_month
FROM project.games_paid_users -- Her kullanıcı için 10 ayı, ay ay olacak şekilde satırlara ekliyoruz. (12nci ay üye olan kullanıcı içinde önceki aylar gözükücek yani) 383kullanıcı*10ay 3830 satır veri oluşuyor.
-- Eklenen her ayın karşısına değer atanacak; Yeni kullanıcı, Boş/Pasif, Aktif, Churn, ChurntoBack. Hesaplamalarımızda çok yardımcı olacak.    

SELECT 
    sum(revenue_amount_usd) AS sum_value,
    DATE_TRUNC('month', payment_date)::DATE AS payment_month
FROM 
    project.games_payments
group by payment_month; -- MRR










