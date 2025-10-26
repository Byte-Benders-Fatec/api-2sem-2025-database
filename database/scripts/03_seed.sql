SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

USE visiona;

-- Seed: system_role
-- Papéis globais do sistema, definidos para controlar o nível de acesso administrativo.
-- Cada papel possui um nível hierárquico (level) que define sua autoridade dentro da plataforma.

INSERT INTO system_role (id, name, description, level, api_key) VALUES
(1, 'Root', 'Acesso total ao sistema. Gerencia todos os administradores.', 100, NULL),
(2, 'Admin', 'Administra usuários e configurações.', 80, NULL),
(3, 'User', 'Usuário comum.', 50, NULL),
(4, 'Guest', 'Acesso público, sem autenticação. Pode visualizar apenas informações abertas.', 5, NULL)
ON DUPLICATE KEY UPDATE name=VALUES(name);



-- Seed: action
-- Ações padrão que representam operações permitidas no sistema.
-- Essas ações são utilizadas para compor permissões em conjunto com os módulos do sistema.

INSERT INTO action (id, name) VALUES
(1, 'View'),
(2, 'Create'),
(3, 'Edit'),
(4, 'Delete')
ON DUPLICATE KEY UPDATE name=VALUES(name);



-- Seed: module
-- Módulos principais do sistema, representando as áreas onde as permissões são aplicadas.
-- Cada permissão é composta por um módulo e uma ação.

INSERT INTO module (id, name) VALUES
(1, 'User'),
(2, 'Property'),
(3, 'Certificate'),
(4, 'Document')
ON DUPLICATE KEY UPDATE name=VALUES(name);



-- Seed: permission (acesso controlado)
-- Permissões pré-definidas do sistema. São imutáveis via interface e não podem ser excluídas ou editadas.
-- Essas permissões são aplicadas apenas via associação a papéis (role_permission).

-- Evita duplicar se já rodou antes
SET SQL_SAFE_UPDATES = 0;
DELETE FROM permission WHERE system_defined = TRUE;
SET SQL_SAFE_UPDATES = 1;

INSERT INTO permission (id, name, module_id, action_id, system_defined)
SELECT UUID(),
       CONCAT(m.name, ':', a.name) AS name,
       m.id, a.id, TRUE
FROM module m
CROSS JOIN action a;



-- Seed: role
-- Papéis padrão do sistema atribuíveis a usuários no contexto da aplicação.
-- Esses papéis são definidos pelo sistema (system_defined = TRUE) e controlam o nível de acesso às funcionalidades.
-- O papel "Usuário" é o padrão para novos usuários inseridos na aplicação (is_default = TRUE).

-- Evita duplicar se já rodou antes
SET SQL_SAFE_UPDATES = 0;
DELETE FROM role WHERE system_defined = TRUE;
SET SQL_SAFE_UPDATES = 1;

INSERT INTO role (id, name, description, is_default, system_defined) VALUES
(UUID(), 'Proprietário', 'Acesso total ao sistema. Gerencia todos os administradores.', FALSE, TRUE),
(UUID(), 'Administrador', 'Administração completa da aplicação.', FALSE, TRUE),
(UUID(), 'Usuário', 'Acesso aos seus recursos próprios: propriedades, certificados, etc.', TRUE, TRUE),
(UUID(), 'Visitante', 'Acesso público, sem autenticação. Pode visualizar apenas informações abertas.', FALSE, TRUE);



-- Seed: role_permission
-- Associação entre papéis (roles) e permissões do sistema.
-- Define o que cada papel pode realizar em cada módulo do sistema.

-- Proprietário: todas as permissões
INSERT INTO role_permission (id, role_id, permission_id)
SELECT UUID(), r.id, p.id
FROM role r
JOIN permission p
WHERE r.name = 'Proprietário';

-- Administrador: todas as permissões
INSERT INTO role_permission (id, role_id, permission_id)
SELECT UUID(), r.id, p.id
FROM role r
JOIN permission p
WHERE r.name = 'Administrador';

-- Usuário: todas as permissões, exceto administração de usuários
INSERT INTO role_permission (id, role_id, permission_id)
SELECT UUID(), r.id, p.id
FROM role r
JOIN permission p ON (
  p.name LIKE 'Property:%'
  OR p.name LIKE 'Certificate:%'
  OR p.name LIKE 'Document:%'
  OR p.name = 'User:View'
)
WHERE r.name = 'Usuário';

-- Visitante: apenas as permissões de visualização
INSERT INTO role_permission (id, role_id, permission_id)
SELECT UUID(), r.id, p.id
FROM role r
JOIN permission p ON p.name LIKE '%:View'
WHERE r.name = 'Visitante';



-- Seed: user
-- Cadastro de usuários do sistema com diferentes níveis de acesso, definidos por system_role_id.
-- Os usuários incluem administradores e usuários comuns.
-- A associação com system_role define o papel global do usuário na plataforma.

INSERT INTO user (id, name, email, cpf, is_active, system_role_id) VALUES
(UUID(), 'Joniel Rodrigues de Oliveira', 'jonielrodriguesdeoliveira@gmail.com', '39957461877', TRUE, 1), -- Root
(UUID(), 'Joniel Rodrigues', 'joniel.rodrigues.oliveira@gmail.com', '77816475993', TRUE, 2), -- Admin
(UUID(), 'Joniel', 'joniel.site@gmail.com', '01234567899', TRUE, 3), -- User
(UUID(), 'Visitante', 'visitante@byte.dev.br', '00000000000', TRUE, 4) -- Guest
ON DUPLICATE KEY UPDATE email=VALUES(email);

-- Guarda os IDs de alguns usuários para FKs
SET @joniel_root_id = (SELECT id FROM user WHERE email='jonielrodriguesdeoliveira@gmail.com'  LIMIT 1);
SET @joniel_admin_id = (SELECT id FROM user WHERE email='joniel.rodrigues.oliveira@gmail.com'    LIMIT 1);
SET @joniel_user_id = (SELECT id FROM user WHERE email='joniel.site@gmail.com'  LIMIT 1);



-- Seed: property
-- (MySQL mínimo; GEO no Mongo)
-- mongo_property_id = ObjectId (24 hex)
-- 1 proprietário por imóvel (owner_user_id)

INSERT INTO property (id, mongo_property_id, owner_user_id, display_name, registry_number)
VALUES
(UUID(), '64b7a2f9c5a1e3d4b6f7a2c9', @joniel_root_id, 'Sítio Santa Rita', 'MAT-0001'),
(UUID(), '64b7a2f9c5a1e3d4b6f7a2ca', @joniel_admin_id, 'Chácara Boa Vista', 'MAT-0002'),
(UUID(), '64b7a2f9c5a1e3d4b6f7a2cb', @joniel_user_id, 'Fazenda Horizonte Azul', 'MAT-0003')
ON DUPLICATE KEY UPDATE registry_number=VALUES(registry_number);

-- Guarda os IDs de propriedades
SET @prop1 = (SELECT id FROM property WHERE registry_number='MAT-0001' LIMIT 1);
SET @prop2 = (SELECT id FROM property WHERE registry_number='MAT-0002' LIMIT 1);
SET @prop3 = (SELECT id FROM property WHERE registry_number='MAT-0003' LIMIT 1);



-- Seed: document
-- document (PDF) - exemplos
-- Troque os caminhos conforme seu secure_file_priv
-- SHOW VARIABLES LIKE 'secure_file_priv';

INSERT INTO document (id, name, mime_type, content)
VALUES (UUID(), 'cert_prop1.pdf', 'application/pdf', LOAD_FILE('/var/lib/mysql-files/cert_prop1.pdf'));
INSERT INTO document (id, name, mime_type, content)
VALUES (UUID(), 'cert_prop2.pdf', 'application/pdf', LOAD_FILE('/var/lib/mysql-files/cert_prop2.pdf'));
INSERT INTO document (id, name, mime_type, content)
VALUES (UUID(), 'cert_prop3.pdf', 'application/pdf', LOAD_FILE('/var/lib/mysql-files/cert_prop3.pdf'));

-- Guarda os IDs de documentos
SET @doc1 = (SELECT id FROM document WHERE name='cert_prop1.pdf' LIMIT 1);
SET @doc2 = (SELECT id FROM document WHERE name='cert_prop2.pdf' LIMIT 1);
SET @doc3 = (SELECT id FROM document WHERE name='cert_prop3.pdf' LIMIT 1);



-- Seed: certificate

INSERT INTO certificate (
  id, property_id, document_id, type, number, issuer, issue_date, expiry_date, status, notes
) VALUES
(UUID(), @prop1, @doc1, 'ownership', 'CERT-0001', 'Cartório Central', '2025-01-15', '2125-01-14', 'valid',  'Certidão de propriedade'),
(UUID(), @prop2, @doc2, 'ownership', 'CERT-0002', 'Cartório Central', '2024-05-01', '2124-05-01', 'valid',  'Certidão de propriedade'),
(UUID(), @prop3, @doc3, 'ownership', 'CERT-0003', 'Cartório Central', '2023-09-10', '2123-09-10', 'valid',  'Certidão de propriedade')
ON DUPLICATE KEY UPDATE number=VALUES(number);
