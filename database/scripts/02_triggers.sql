
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

USE visiona;

-- ===============================================================
-- 1) USER: Normalização/validação de CPF
--    - Remove qualquer caractere não numérico
--    - Garante 11 dígitos no BEFORE INSERT/UPDATE
-- ===============================================================

DELIMITER //

CREATE TRIGGER trg_user_cpf_normalize_bi
BEFORE INSERT ON user
FOR EACH ROW
BEGIN
  -- Normaliza: remove tudo que não for dígito
  SET NEW.cpf = REGEXP_REPLACE(NEW.cpf, '[^0-9]', '');
  -- Valida tamanho = 11
  IF NEW.cpf IS NULL OR CHAR_LENGTH(NEW.cpf) <> 11 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'CPF inválido: é necessário informar 11 dígitos (somente números).';
  END IF;
END;
//

CREATE TRIGGER trg_user_cpf_normalize_bu
BEFORE UPDATE ON user
FOR EACH ROW
BEGIN
  IF NEW.cpf IS NOT NULL THEN
    SET NEW.cpf = REGEXP_REPLACE(NEW.cpf, '[^0-9]', '');
    IF CHAR_LENGTH(NEW.cpf) <> 11 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CPF inválido: é necessário informar 11 dígitos (somente números).';
    END IF;
  END IF;
END;
//

DELIMITER ;

-- ===============================================================
-- 2) PROPERTY: Normalizar ObjectId do MongoDB
--    - Converte para minúsculas (forma comum de exibir ObjectId)
--    - (A checagem de formato 24-hex já está no CHECK da tabela)
-- ===============================================================

DELIMITER //

CREATE TRIGGER trg_property_mongoid_norm_bi
BEFORE INSERT ON property
FOR EACH ROW
BEGIN
  SET NEW.mongo_property_id = LOWER(NEW.mongo_property_id);
END;
//

CREATE TRIGGER trg_property_mongoid_norm_bu
BEFORE UPDATE ON property
FOR EACH ROW
BEGIN
  IF NEW.mongo_property_id IS NOT NULL THEN
    SET NEW.mongo_property_id = LOWER(NEW.mongo_property_id);
  END IF;
END;
//

DELIMITER ;

-- ===============================================================
-- 3) CERTIFICATE: Regras automáticas de status e consistência
--    - Se expiry_date < hoje => status = 'expired'
--    - Checa coerência issue_date <= expiry_date (quando ambos existem)
-- ===============================================================

DELIMITER //

CREATE TRIGGER trg_certificate_status_bi
BEFORE INSERT ON certificate
FOR EACH ROW
BEGIN
  -- Coerência de datas
  IF NEW.issue_date IS NOT NULL AND NEW.expiry_date IS NOT NULL AND NEW.expiry_date < NEW.issue_date THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Data inválida: expiry_date não pode ser anterior a issue_date.';
  END IF;

  -- Status automático por validade
  IF NEW.expiry_date IS NOT NULL AND NEW.expiry_date < CURRENT_DATE() THEN
    SET NEW.status = 'expired';
  END IF;
END;
//

CREATE TRIGGER trg_certificate_status_bu
BEFORE UPDATE ON certificate
FOR EACH ROW
BEGIN
  -- Coerência de datas
  IF NEW.issue_date IS NOT NULL AND NEW.expiry_date IS NOT NULL AND NEW.expiry_date < NEW.issue_date THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Data inválida: expiry_date não pode ser anterior a issue_date.';
  END IF;

  -- Status automático por validade
  IF NEW.expiry_date IS NOT NULL AND NEW.expiry_date < CURRENT_DATE() THEN
    SET NEW.status = 'expired';
  END IF;
END;
//

DELIMITER ;
