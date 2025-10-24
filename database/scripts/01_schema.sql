
CREATE DATABASE IF NOT EXISTS visiona
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE visiona;

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Tabela: system_role
-- Finalidade: Armazena os papéis globais de acesso do sistema, como Super Admin, Admin, User e Viewer.
-- Cada papel possui um Id único, nome, descrição e nível hierárquico.

CREATE TABLE IF NOT EXISTS system_role (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID do papel global do sistema',
    name VARCHAR(50) NOT NULL UNIQUE COMMENT 'Nome do papel (ex: Admin, Viewer)',
    description VARCHAR(255) NOT NULL COMMENT 'Descrição do papel e sua função no sistema',
    level INT NOT NULL UNIQUE COMMENT 'Nível hierárquico do papel (valores maiores indicam maior acesso)'
) COMMENT = 'Tabela de definição de papéis de acesso globais do sistema';



-- Tabela: user
-- Finalidade: Armazena os dados cadastrais e de acesso lógico dos usuários do sistema.

CREATE TABLE IF NOT EXISTS user (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()) COMMENT 'UUID do usuário',
    name VARCHAR(100) NOT NULL COMMENT 'Nome completo do usuário',
    email VARCHAR(100) NOT NULL UNIQUE COMMENT 'E-mail utilizado para login',
    cpf CHAR(11) NOT NULL UNIQUE COMMENT 'CPF só dígitos (11)',
	CHECK (cpf REGEXP '^[0-9]{11}$'),
    
    is_active BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Indica se o usuário está ativo no sistema',
    system_role_id INT NOT NULL COMMENT 'ID do papel global do sistema associado ao usuário',

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Data de criação do usuário',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Data da última atualização do usuário',
    deleted_at DATETIME DEFAULT NULL COMMENT 'Data de exclusão lógica (soft delete)',

    FOREIGN KEY (system_role_id) REFERENCES system_role(id)
) COMMENT = 'Tabela de usuários com ciclo de vida e referência ao papel global';



-- Tabela: user_photo
-- Finalidade: Armazena fotos de perfil dos usuários diretamente no banco de dados, com controle de ciclo de vida e auditoria.

CREATE TABLE IF NOT EXISTS user_photo (
    user_id CHAR(36) PRIMARY KEY COMMENT 'Referência ao usuário, também usada como chave primária',
    name VARCHAR(255) NOT NULL COMMENT 'Nome original do arquivo',
    mime_type VARCHAR(100) NOT NULL COMMENT 'Tipo MIME do arquivo (image/png, image/jpeg, etc)',
    content MEDIUMBLOB NOT NULL COMMENT 'Conteúdo binário da imagem (até 16 MB)',

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Data de criação do documento',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última modificação do documento',
    deleted_at DATETIME DEFAULT NULL COMMENT 'Data de exclusão lógica do documento',

    CONSTRAINT fk_user_photo_user FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
) COMMENT = 'Fotos de perfil dos usuários armazenadas no banco de dados, vinculadas diretamente por ID ao usuário';



-- Tabela: action
-- Finalidade: Define as ações possíveis sobre os módulos do sistema (ex: visualizar, criar, editar, excluir).

CREATE TABLE IF NOT EXISTS action (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID da ação',
    name VARCHAR(50) NOT NULL UNIQUE COMMENT 'Nome da ação (ex: View, Create, Edit, Delete)'
) COMMENT = 'Ações possíveis aplicadas a módulos do sistema';



-- Tabela: module
-- Finalidade: Define os módulos do sistema aos quais as permissões podem estar associadas (ex: projetos, atividades).

CREATE TABLE IF NOT EXISTS module (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID do módulo',
    name VARCHAR(50) NOT NULL UNIQUE COMMENT 'Nome do módulo (ex: Project, Activity)'
) COMMENT = 'Módulos funcionais do sistema onde permissões são aplicadas';



-- Tabela: permission
-- Finalidade: Define as permissões disponíveis no sistema, compostas por um módulo e uma ação.

CREATE TABLE IF NOT EXISTS permission (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()) COMMENT 'UUID da permissão',
    name VARCHAR(100) NOT NULL UNIQUE COMMENT 'Nome da permissão (ex: Projetos - Visualizar)',
    module_id INT NOT NULL COMMENT 'ID do módulo relacionado à permissão',
    action_id INT NOT NULL COMMENT 'ID da ação relacionada à permissão',
    system_defined BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Define se a permissão é criada pelo sistema (não editável, não deletável)',

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Data de criação da permissão',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Data da última atualização',
    deleted_at DATETIME DEFAULT NULL COMMENT 'Data de exclusão lógica da permissão (soft delete)',

    FOREIGN KEY (module_id) REFERENCES module(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (action_id) REFERENCES action(id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Permissões disponíveis no sistema, associadas a um módulo e a uma ação';



-- Tabela: role
-- Finalidade: Define os papéis atribuíveis a usuários dentro de projetos ou times.

CREATE TABLE IF NOT EXISTS role (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()) COMMENT 'UUID do papel de projeto/time',
    name VARCHAR(50) NOT NULL UNIQUE COMMENT 'Nome do papel (ex: Coordenador, Colaborador)',
    description VARCHAR(255) NOT NULL COMMENT 'Descrição da função deste papel dentro de um projeto',
    is_default BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Indica se este é o papel padrão ao adicionar usuários',
    system_defined BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Define se o papel é criado pelo sistema (não editável, não deletável)',
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Data de criação do papel',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última atualização do papel',
    deleted_at DATETIME DEFAULT NULL COMMENT 'Data de exclusão lógica (soft delete)'
) COMMENT = 'Tabela de papéis atribuíveis aos usuários dentro de projetos';



-- Tabela: role_permission
-- Finalidade: Associa papéis de projeto a permissões específicas do sistema.

CREATE TABLE IF NOT EXISTS role_permission (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()) COMMENT 'UUID da associação entre papel e permissão',
    role_id CHAR(36) NOT NULL COMMENT 'UUID do papel atribuído',
    permission_id CHAR(36) NOT NULL COMMENT 'UUID da permissão concedida ao papel',

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Data de criação da associação',
    deleted_at DATETIME DEFAULT NULL COMMENT 'Data de exclusão lógica (soft delete)',

	-- Impede que uma mesma permissão seja atribuída mais de uma vez a um papel
	UNIQUE KEY unique_role_permission (role_id, permission_id),

    FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permission(id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Tabela que relaciona papéis atribuíveis aos usuários com permissões específicas do sistema';



-- Tabela: document
-- Finalidade: Armazena arquivos binários (PDFs) diretamente no banco de dados, com controle de ciclo de vida.

CREATE TABLE IF NOT EXISTS document (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()) COMMENT 'UUID do documento',
    name VARCHAR(255) NOT NULL COMMENT 'Nome original do arquivo',
    mime_type VARCHAR(100) NOT NULL DEFAULT 'application/pdf' COMMENT 'Tipo MIME do arquivo (geralmente application/pdf)',
    content MEDIUMBLOB NOT NULL COMMENT 'Conteúdo binário do arquivo PDF (até 16 MB)',

    is_active BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Indica se o documento está ativo para uso ou exibição',

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Data de criação do documento',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última modificação do documento',
    deleted_at DATETIME DEFAULT NULL COMMENT 'Data de exclusão lógica do documento'
) COMMENT = 'Documentos armazenados diretamente no banco de dados, anexáveis a projetos ou atividades';



-- Tabela: two_fa_code
-- Finalidade: Armazena códigos de verificação temporários para autenticação em duas etapas via e-mail.
-- Utilizada para validar acessos com código de 6 dígitos enviado após login, redefinição de senha ou confirmação de ações críticas.

CREATE TABLE IF NOT EXISTS two_fa_code (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()) COMMENT 'UUID do código de verificação gerado',
    user_id CHAR(36) NOT NULL COMMENT 'UUID do usuário que solicitou o código de verificação',
    code_hash VARCHAR(255) NOT NULL COMMENT 'Hash seguro do código de 6 dígitos enviado ao e-mail',
    is_double BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Indica se o código é dublo (12 dígitos) ou simples (6 dígitos)',
    attempts INT DEFAULT 0 COMMENT 'Número de tentativas realizadas com esse código',
    max_attempts INT DEFAULT 5 COMMENT 'Número máximo de tentativas permitidas',
    status ENUM('pending', 'verified', 'denied') DEFAULT 'pending' COMMENT 'Estado da verificação: pendente, verificado ou negado',
    type ENUM('login', 'password_reset', 'password_change', 'critical_action') NOT NULL DEFAULT 'login' COMMENT 'Finalidade do código de verificação gerado',
    expires_at DATETIME NOT NULL COMMENT 'Data e hora de expiração do código',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Data de criação do código',

    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Armazena códigos de verificação temporários para autenticação em dois fatores e validação de ações sensíveis.';



-- Tabela: user_password
-- Finalidade: Armazena senhas associadas ao usuário, com suporte a senhas permanentes e temporárias.
-- Permite o controle de expiração, tentativas de autenticação, histórico, níveis de bloqueio e prevenção de reuso de senhas anteriores.
-- É utilizada para autenticação segura de usuários.

CREATE TABLE IF NOT EXISTS user_password (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()) COMMENT 'UUID da entrada de senha',
    user_id CHAR(36) NOT NULL COMMENT 'UUID do usuário ao qual a senha está associada',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Hash seguro da senha (permanente ou temporária)',
    is_temp BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Indica se a senha é temporária (ex: recuperação de senha)',
    attempts INT DEFAULT 0 COMMENT 'Número de tentativas de login com esta senha',
    max_attempts INT DEFAULT 5 COMMENT 'Número máximo de tentativas permitidas antes de bloquear esta senha',
    locked_until DATETIME DEFAULT NULL COMMENT 'Data/hora até a qual esta senha está temporariamente bloqueada após tentativas inválidas',
    lockout_level INT NOT NULL DEFAULT 0 COMMENT 'Nível de bloqueio aplicado ao usuário',
    status ENUM('valid', 'expired', 'blocked') DEFAULT 'valid' COMMENT 'Estado da senha: válida, expirada ou bloqueada',
    expires_at DATETIME DEFAULT NULL COMMENT 'Data e hora de expiração da senha (se temporária)',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Data de criação da senha',
    deleted_at DATETIME DEFAULT NULL COMMENT 'Soft delete ou inativação da senha',

    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT = 'Armazena senhas com suporte a temporárias, tentativas, bloqueios, expiração e níveis de segurança.';



-- Tabela: property
-- Finalidade: Armazena o vínculo e metadados mínimos das propriedades.
-- Os dados GEO e detalhes ficam no MongoDB.

CREATE TABLE IF NOT EXISTS property (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()) COMMENT 'UUID do imóvel (MySQL)',
    mongo_property_id CHAR(24) NOT NULL UNIQUE COMMENT 'ObjectId (hex) da propriedade no MongoDB',
    owner_user_id CHAR(36) NOT NULL COMMENT 'Proprietário atual (um único dono por imóvel)',

    display_name VARCHAR(255) DEFAULT NULL COMMENT 'Nome amigável (ex.: Sítio São José)',
    registry_number VARCHAR(100) DEFAULT NULL COMMENT 'Matrícula/inscrição (se desejar manter aqui)',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME DEFAULT NULL,

    CONSTRAINT fk_property_owner FOREIGN KEY (owner_user_id) REFERENCES user(id) ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Valida formato 24-hex (MySQL 8.0+; senão, valide na app)
    CONSTRAINT chk_property_mongo_id CHECK (mongo_property_id REGEXP '^[0-9a-fA-F]{24}$')
) COMMENT='Propriedade mínima (owner + ponte p/ MongoDB)';



-- Tabela: certificate
-- Finalidade: Certificado da propriedade (um por imóvel, já que há um único dono, o dono é inferido via property.owner_user_id).

CREATE TABLE IF NOT EXISTS certificate (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    property_id CHAR(36) NOT NULL COMMENT 'FK property (dono inferido via property.owner_user_id)',
    document_id CHAR(36) NOT NULL COMMENT 'PDF em document',

    type ENUM('ownership','environmental','georeferencing','compliance','other')
         NOT NULL DEFAULT 'ownership',
    number VARCHAR(100) DEFAULT NULL COMMENT 'Número/identificador do certificado',
    issuer VARCHAR(255) DEFAULT NULL COMMENT 'Órgão emissor',
    issue_date DATE DEFAULT NULL,
    expiry_date DATE DEFAULT NULL,
    status ENUM('valid','expired','revoked') NOT NULL DEFAULT 'valid',
    notes VARCHAR(255) DEFAULT NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME DEFAULT NULL,

    CONSTRAINT fk_cert_property FOREIGN KEY (property_id) REFERENCES property(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cert_document FOREIGN KEY (document_id) REFERENCES document(id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Garante 1 certificado por imóvel (se quiser permitir vários, remova esta UNIQUE)
    UNIQUE KEY uq_certificate_unique_per_property (property_id),

    INDEX idx_certificate_status (status, expiry_date)
) COMMENT='Certificado do imóvel (1:1), PDF em document';
