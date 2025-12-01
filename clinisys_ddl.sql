

-- ============================================================================
-- 1. CONTROLE DE ACESSO E USUÁRIOS (Herança)
-- ============================================================================

-- Tabela Mãe: Usuarios
CREATE TABLE usuarios (
    usuario_id SERIAL PRIMARY KEY,
    nome_completo VARCHAR(200) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    data_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tipo_usuario VARCHAR(20) NOT NULL CHECK (tipo_usuario IN ('ALUNO', 'PROFESSOR', 'RECEPCIONISTA')),
    
    -- Atributo Composto: Endereço
    logradouro VARCHAR(255),
    numero VARCHAR(10),
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    cep VARCHAR(8),
    
    CONSTRAINT chk_cpf_format CHECK (LENGTH(cpf) = 11),
    CONSTRAINT chk_cep_format CHECK (LENGTH(cep) = 8 OR cep IS NULL)
);

CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_cpf ON usuarios(cpf);
CREATE INDEX idx_usuarios_tipo ON usuarios(tipo_usuario);

-- Tabela Filha: Recepcionistas
CREATE TABLE recepcionistas (
    usuario_id INTEGER PRIMARY KEY,
    telefone VARCHAR(15),
    
    CONSTRAINT fk_recepcionistas_usuarios 
        FOREIGN KEY (usuario_id) 
        REFERENCES usuarios(usuario_id) 
        ON DELETE CASCADE
);

-- Tabela Filha: Professores
CREATE TABLE professores (
    usuario_id INTEGER PRIMARY KEY,
    especialidade VARCHAR(100),
    telefone VARCHAR(15),
    
    CONSTRAINT fk_professores_usuarios 
        FOREIGN KEY (usuario_id) 
        REFERENCES usuarios(usuario_id) 
        ON DELETE CASCADE
);

-- Tabela Filha: Alunos
CREATE TABLE alunos (
    usuario_id INTEGER PRIMARY KEY,
    matricula VARCHAR(20) NOT NULL UNIQUE,
    telefone VARCHAR(15),
    clinica_id INTEGER, -- FK adicionada após criação da tabela clinicas
    
    CONSTRAINT fk_alunos_usuarios 
        FOREIGN KEY (usuario_id) 
        REFERENCES usuarios(usuario_id) 
        ON DELETE CASCADE
);

CREATE INDEX idx_alunos_matricula ON alunos(matricula);

-- ============================================================================
-- 2. ESTRUTURA ORGANIZACIONAL
-- ============================================================================

-- Tabela: Clínicas
CREATE TABLE clinicas (
    clinica_id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    num_leitos INTEGER NOT NULL DEFAULT 0,
    num_alunos INTEGER NOT NULL DEFAULT 0,
    
    CONSTRAINT chk_num_leitos_positivo CHECK (num_leitos >= 0),
    CONSTRAINT chk_num_alunos_positivo CHECK (num_alunos >= 0)
);


ALTER TABLE alunos
    ADD CONSTRAINT fk_alunos_clinicas 
    FOREIGN KEY (clinica_id) 
    REFERENCES clinicas(clinica_id) 
    ON DELETE RESTRICT;

ALTER TABLE professores
    ADD CONSTRAINT fk_professores_clinicas 
    FOREIGN KEY (clinica_id) 
    REFERENCES clinicas(clinica_id) 
    ON DELETE RESTRICT;


ALTER TABLE professores
    ADD COLUMN clinica_id INTEGER;

CREATE INDEX idx_alunos_clinica ON alunos(clinica_id);
CREATE INDEX idx_professores_clinica ON professores(clinica_id);

-- ============================================================================
-- 3. PACIENTES E PRONTUÁRIOS
-- ============================================================================

-- Tabela: Pacientes
CREATE TABLE pacientes (
    paciente_id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    data_nascimento DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'AGUARDANDO_TRIAGEM' 
        CHECK (status IN ('AGUARDANDO_TRIAGEM', 'EM_TRATAMENTO', 'ALTA')),
    clinica_id INTEGER,
    
    -- Atributo Composto: Endereço (Achatado)
    logradouro VARCHAR(255),
    numero VARCHAR(10),
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    cep VARCHAR(8),
    
    CONSTRAINT fk_pacientes_clinicas 
        FOREIGN KEY (clinica_id) 
        REFERENCES clinicas(clinica_id) 
        ON DELETE RESTRICT,
    
    CONSTRAINT chk_paciente_cpf_format CHECK (LENGTH(cpf) = 11),
    CONSTRAINT chk_paciente_cep_format CHECK (LENGTH(cep) = 8 OR cep IS NULL),
    CONSTRAINT chk_data_nascimento CHECK (data_nascimento <= CURRENT_DATE)
);

CREATE INDEX idx_pacientes_cpf ON pacientes(cpf);
CREATE INDEX idx_pacientes_status ON pacientes(status);
CREATE INDEX idx_pacientes_clinica ON pacientes(clinica_id);

-- Tabela: Prontuários (Relação 1:1 com Pacientes)
CREATE TABLE prontuarios (
    prontuario_id SERIAL PRIMARY KEY,
    paciente_id INTEGER NOT NULL UNIQUE, 
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_prontuarios_pacientes 
        FOREIGN KEY (paciente_id) 
        REFERENCES pacientes(paciente_id) 
        ON DELETE CASCADE
);

CREATE INDEX idx_prontuarios_paciente ON prontuarios(paciente_id);

-- ============================================================================
-- 4. CATÁLOGOS E TIPOS
-- ============================================================================

-- Tabela: Tipos de Atendimentos
CREATE TABLE tipos_atendimentos (
    tipo_id SERIAL PRIMARY KEY,
    nome_tipo VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT
);

-- Tabela: Catálogo de Procedimentos
CREATE TABLE catalogo_procedimentos (
    catalogo_id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nome VARCHAR(200) NOT NULL,
    descricao TEXT
);

CREATE INDEX idx_catalogo_procedimentos_codigo ON catalogo_procedimentos(codigo);

-- ============================================================================
-- 5. CORE DO NEGÓCIO (Atendimentos e Procedimentos)
-- ============================================================================

-- Tabela: Atendimentos
CREATE TABLE atendimentos (
    atendimento_id SERIAL PRIMARY KEY,
    data_hora_agendada TIMESTAMP NOT NULL,
    data_hora_inicio TIMESTAMP,
    data_hora_fim TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'AGENDADO' 
        CHECK (status IN ('AGENDADO', 'EM_ANDAMENTO', 'CONCLUIDO', 'CANCELADO')),
    observacoes TEXT,
    
    -- Chaves Estrangeiras
    aluno_id INTEGER NOT NULL, -- Quem realiza
    paciente_id INTEGER NOT NULL, -- Quem recebe
    tipo_id INTEGER NOT NULL, -- Tipo do atendimento
    
    CONSTRAINT fk_atendimentos_alunos 
        FOREIGN KEY (aluno_id) 
        REFERENCES alunos(usuario_id) 
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_atendimentos_pacientes 
        FOREIGN KEY (paciente_id) 
        REFERENCES pacientes(paciente_id) 
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_atendimentos_tipos 
        FOREIGN KEY (tipo_id) 
        REFERENCES tipos_atendimentos(tipo_id) 
        ON DELETE RESTRICT,
    
    CONSTRAINT chk_data_hora_fim CHECK (data_hora_fim IS NULL OR data_hora_fim >= data_hora_inicio),
    CONSTRAINT chk_data_hora_inicio CHECK (data_hora_inicio IS NULL OR data_hora_inicio >= data_hora_agendada)
);

CREATE INDEX idx_atendimentos_aluno ON atendimentos(aluno_id);
CREATE INDEX idx_atendimentos_paciente ON atendimentos(paciente_id);
CREATE INDEX idx_atendimentos_tipo ON atendimentos(tipo_id);
CREATE INDEX idx_atendimentos_status ON atendimentos(status);
CREATE INDEX idx_atendimentos_data_agendada ON atendimentos(data_hora_agendada);

-- Tabela: Procedimentos (Registro de Execução)
CREATE TABLE procedimentos (
    procedimento_id SERIAL PRIMARY KEY,
    data_realizacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacoes_aluno TEXT,
    
    -- Chaves Estrangeiras (N:1)
    prontuario_id INTEGER NOT NULL, -- Vinculado ao prontuário do paciente
    atendimento_id INTEGER NOT NULL, -- Vinculado ao atendimento específico
    catalogo_id INTEGER NOT NULL, -- Qual procedimento foi executado
    
    CONSTRAINT fk_procedimentos_prontuarios 
        FOREIGN KEY (prontuario_id) 
        REFERENCES prontuarios(prontuario_id) 
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_procedimentos_atendimentos 
        FOREIGN KEY (atendimento_id) 
        REFERENCES atendimentos(atendimento_id) 
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_procedimentos_catalogo 
        FOREIGN KEY (catalogo_id) 
        REFERENCES catalogo_procedimentos(catalogo_id) 
        ON DELETE RESTRICT
);

CREATE INDEX idx_procedimentos_prontuario ON procedimentos(prontuario_id);
CREATE INDEX idx_procedimentos_atendimento ON procedimentos(atendimento_id);
CREATE INDEX idx_procedimentos_catalogo ON procedimentos(catalogo_id);
CREATE INDEX idx_procedimentos_data ON procedimentos(data_realizacao);

-- ============================================================================
-- 6. CONTROLE DE AUTORIZAÇÕES
-- ============================================================================

-- Tabela: Solicitações de Alta
CREATE TABLE solicitacoes_alta (
    solicitacao_id SERIAL PRIMARY KEY,
    data_solicitacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo_aluno TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDENTE' 
        CHECK (status IN ('PENDENTE', 'APROVADA', 'RECUSADA')),
    data_analise TIMESTAMP,
    observacao_professor TEXT,
    
    -- Chaves Estrangeiras
    aluno_id INTEGER NOT NULL, -- Quem solicitou
    professor_id INTEGER, -- Quem analisou (Nullable até aprovação)
    atendimento_id INTEGER NOT NULL, -- Atendimento vinculado à solicitação
    
    CONSTRAINT fk_solicitacoes_alunos 
        FOREIGN KEY (aluno_id) 
        REFERENCES alunos(usuario_id) 
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_solicitacoes_professores 
        FOREIGN KEY (professor_id) 
        REFERENCES professores(usuario_id) 
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_solicitacoes_atendimentos 
        FOREIGN KEY (atendimento_id) 
        REFERENCES atendimentos(atendimento_id) 
        ON DELETE RESTRICT,
    
    CONSTRAINT chk_data_analise CHECK (
        (status = 'PENDENTE' AND data_analise IS NULL) OR 
        (status IN ('APROVADA', 'RECUSADA') AND data_analise IS NOT NULL)
    )
);

CREATE INDEX idx_solicitacoes_aluno ON solicitacoes_alta(aluno_id);
CREATE INDEX idx_solicitacoes_professor ON solicitacoes_alta(professor_id);
CREATE INDEX idx_solicitacoes_atendimento ON solicitacoes_alta(atendimento_id);
CREATE INDEX idx_solicitacoes_status ON solicitacoes_alta(status);