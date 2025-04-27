-- ПУНКТ 1: Створення схеми та завантаження даних
CREATE DATABASE IF NOT EXISTS pandemic;
USE pandemic;

-- Підрахунок кількості записів в оригінальній таблиці infectious_cases
SELECT COUNT(*) FROM pandemic.infectious_cases;

-- ПУНКТ 2: Нормалізація таблиці infectious_cases до 3НФ
CREATE TABLE pandemic.entities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity VARCHAR(255),
    code VARCHAR(255)
);

INSERT INTO pandemic.entities (entity, code)
SELECT DISTINCT Entity, Code
FROM pandemic.infectious_cases;

CREATE TABLE pandemic.cases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity_id INT NOT NULL,
    year INT,
    number_rabies FLOAT,
    number_malaria FLOAT,
    number_measles FLOAT,
    number_meningitis FLOAT,
    number_tuberculosis FLOAT,
    FOREIGN KEY (entity_id) REFERENCES pandemic.entities(id)
);

INSERT INTO pandemic.cases (entity_id, year, number_rabies, number_malaria, number_measles, number_meningitis, number_tuberculosis)
SELECT 
    e.id,
    ic.Year,
    CAST(NULLIF(ic.Number_rabies, '') AS FLOAT),
    CAST(NULLIF(ic.Number_malaria, '') AS FLOAT),
    NULL,
    NULL,
    NULL
FROM pandemic.infectious_cases ic
JOIN pandemic.entities e ON ic.Entity = e.entity AND ic.Code = e.code;

-- ПУНКТ 3: Аналіз даних для Number_rabies
SELECT 
    e.entity, 
    e.code,
    AVG(c.number_rabies) AS avg_rabies,
    MIN(c.number_rabies) AS min_rabies,
    MAX(c.number_rabies) AS max_rabies,
    SUM(c.number_rabies) AS sum_rabies
FROM pandemic.cases c
JOIN pandemic.entities e ON c.entity_id = e.id
WHERE c.number_rabies IS NOT NULL
GROUP BY e.entity, e.code
ORDER BY avg_rabies DESC
LIMIT 10;

-- ПУНКТ 4.1: Побудова дати 1 січня відповідного року
SELECT 
    id,
    year,
    DATE(CONCAT(year, '-01-01')) AS first_jan_date,
    CURRENT_DATE() AS today_date,
    TIMESTAMPDIFF(YEAR, DATE(CONCAT(year, '-01-01')), CURRENT_DATE()) AS diff_years
FROM pandemic.cases;

-- ПУНКТ 5: Створення власної функції для різниці в роках
DROP FUNCTION IF EXISTS calculate_years_difference;
DELIMITER $$
CREATE FUNCTION calculate_years_difference(input_year INT)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, DATE(CONCAT(input_year, '-01-01')), CURRENT_DATE());
END$$
DELIMITER ;

-- Використання функції
SELECT 
    id, 
    year,
    calculate_years_difference(year) AS diff_years
FROM pandemic.cases;
