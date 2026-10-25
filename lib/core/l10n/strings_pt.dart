import '../../features/alerts/machine_alert.dart';
import '../../features/auth/auth_service.dart';
import '../../features/cards/card_models.dart';
import '../../features/control/control_models.dart';
import '../../features/machine/machine_models.dart';
import 'app_strings.dart';

class PtStrings extends AppStrings {
  const PtStrings();

  // Common
  @override
  String get tryAgain => 'Tentar novamente';
  @override
  String get back => 'Voltar';
  @override
  String get view => 'Ver';
  @override
  String get done => 'Concluir';
  @override
  String get close => 'Fechar';
  @override
  String comingSoon(String feature) => '$feature em breve.';

  // Splash
  @override
  String get appTagline => 'Organize suas cartas de Magic';
  @override
  String get splashConnecting => 'Conectando ao servidor…';
  @override
  String get splashCheckingSession => 'Verificando sessão…';
  @override
  String get serverUnreachableTitle => 'Não foi possível conectar ao servidor';
  @override
  String get serverUnreachableHint =>
      'Verifique sua internet e tente novamente.';

  // Login
  @override
  String get loginSubtitle => 'Entre para gerenciar seu organizador';
  @override
  String get usernameOrEmail => 'Usuário ou e-mail';
  @override
  String get password => 'Senha';
  @override
  String get showPassword => 'Mostrar senha';
  @override
  String get hidePassword => 'Ocultar senha';
  @override
  String get rememberMe => 'Lembrar de mim';
  @override
  String get signIn => 'Entrar';
  @override
  String get forgotPassword => 'Esqueci minha senha';
  @override
  String get orDivider => 'ou';
  @override
  String get continueWithGoogle => 'Continuar com Google';
  @override
  String get newHere => 'Novo por aqui?';
  @override
  String get createAccount => 'Criar conta';
  @override
  String get passwordRecoverySoon => 'Recuperação de senha em breve.';
  @override
  String get signUpSoon => 'Cadastro em breve.';
  @override
  String get usernameRequired => 'Informe seu usuário ou e-mail';
  @override
  String get invalidEmail => 'E-mail inválido';
  @override
  String get passwordRequired => 'Informe sua senha';
  @override
  String get passwordTooShort => 'A senha deve ter ao menos 6 caracteres';
  @override
  String authError(AuthFailure failure) => switch (failure) {
        AuthFailure.invalidCredentials => 'Usuário ou senha inválidos.',
        AuthFailure.serverUnreachable =>
          'Sem conexão com o servidor. Tente novamente.',
        AuthFailure.serverError => 'Erro no servidor. Tente novamente.',
        AuthFailure.googleCancelled => 'Login com Google cancelado.',
        AuthFailure.googleTokenMissing =>
          'Não foi possível obter o token do Google.',
      };

  // Home and menu
  @override
  String get noMachineTitle => 'Nenhuma máquina vinculada';
  @override
  String get noMachineBody =>
      'Vincule seu organizador para acompanhar e controlar a separação das cartas.';
  @override
  String get machineLinkedBody => 'Vinculada à sua conta';
  @override
  String get menuMachineControl => 'Controle da máquina';
  @override
  String get menuCardsInFolders => 'Cartas nas pastas';
  @override
  String get menuCsvReport => 'Relatório CSV';
  @override
  String get menuSortingRules => 'Regras de ordenação';
  @override
  String get linkMachine => 'Vincular máquina';
  @override
  String get alerts => 'Alertas';
  @override
  String get settings => 'Configurações';
  @override
  String get signOut => 'Sair';

  // Link machine
  @override
  String get selectMachine => 'Selecione sua máquina';
  @override
  String get scanningForMachines => 'Procurando máquinas CardForge por perto…';
  @override
  String get scanAgain => 'Buscar novamente';
  @override
  String get noMachinesFound => 'Nenhuma máquina encontrada';
  @override
  String get noMachinesHint =>
      'Confirme que a máquina está ligada e por perto e busque de novo.';
  @override
  String get scanFailedTitle => 'Falha na busca por Bluetooth';
  @override
  String get enterMachinePassword => 'Senha da máquina';
  @override
  String machinePasswordHint(String machineName) =>
      'Informe a senha de $machineName para permitir a vinculação.';
  @override
  String get machinePassword => 'Senha da máquina';
  @override
  String get machinePasswordRequired => 'Informe a senha da máquina';
  @override
  String get verifyPassword => 'Verificar senha';
  @override
  String get chooseAnotherMachine => 'Escolher outra máquina';
  @override
  String get wifiQuestionTitle => 'Enviar dados do Wi-Fi?';
  @override
  String get wifiQuestionBody =>
      'A máquina precisa de Wi-Fi para falar com o servidor. '
      'Enviar agora o nome e a senha da sua rede?';
  @override
  String get sendWifi => 'Sim, enviar Wi-Fi';
  @override
  String get skipWifi => 'Pular por enquanto';
  @override
  String get wifiFormTitle => 'Dados do Wi-Fi';
  @override
  String get networkName => 'Nome da rede (SSID)';
  @override
  String get networkNameRequired => 'Informe o nome da rede';
  @override
  String get wifiPassword => 'Senha do Wi-Fi';
  @override
  String get wifiPasswordHint => 'Deixe vazio para redes abertas';
  @override
  String get wifiTip =>
      'Dica: alguns Raspberry Pi 3 só aceitam redes de 2,4 GHz.';
  @override
  String get sendAndLink => 'Enviar e vincular';
  @override
  String get linkingTitle => 'Vinculando sua máquina';
  @override
  String get linkingHint =>
      'A máquina vai confirmar quando tudo estiver pronto. '
      'Isso pode levar até um minuto.';
  @override
  String linkStep(LinkStep step) => switch (step) {
        LinkStep.sendingWifi => 'Enviando os dados do Wi-Fi…',
        LinkStep.waitingForWifi => 'Aguardando a máquina conectar ao Wi-Fi…',
        LinkStep.linkingAccount => 'Vinculando a máquina à sua conta…',
        LinkStep.done => 'Concluído',
      };
  @override
  String get linkSuccessTitle => 'Máquina vinculada!';
  @override
  String linkSuccessBody(String machineName) =>
      '$machineName está pronta. Inicie uma ordenação na tela de controle da máquina.';
  @override
  String get linkFailureTitle => 'Não foi possível vincular a máquina';
  @override
  String linkFailure(MachineLinkFailure failure) => switch (failure) {
        MachineLinkFailure.bluetoothUnavailable =>
          'O Bluetooth está indisponível. Ative-o e tente de novo.',
        MachineLinkFailure.wrongPassword => 'Senha da máquina incorreta.',
        MachineLinkFailure.connectionLost =>
          'A conexão com a máquina foi perdida.',
        MachineLinkFailure.wifiFailed =>
          'A máquina não conseguiu conectar a essa rede Wi-Fi. '
              'Confira o nome e a senha.',
        MachineLinkFailure.accountLinkFailed =>
          'A máquina conectou, mas a vinculação à sua conta falhou.',
        MachineLinkFailure.timeout =>
          'A máquina não confirmou a tempo. Tente novamente.',
        MachineLinkFailure.notImplemented =>
          'A vinculação por Bluetooth ainda não está disponível nesta versão.',
        MachineLinkFailure.unknown => 'Algo deu errado. Tente novamente.',
      };

  // Cards in folders
  @override
  String get searchCardsHint => 'Pesquisar carta pelo nome';
  @override
  String get clearSearch => 'Limpar pesquisa';
  @override
  String get allCardsHeader => 'Cartas nas suas pastas';
  @override
  String resultsFor(String query) => 'Resultados para “$query”';
  @override
  String cardsCount(int count) => count == 1 ? '1 carta' : '$count cartas';
  @override
  String copiesCount(int quantity) =>
      quantity == 1 ? '1 cópia' : '$quantity cópias';
  @override
  String folderLabel(int folder) => 'Pasta $folder';
  @override
  String get cardsEmptyTitle => 'Nenhuma carta nas pastas ainda';
  @override
  String get cardsEmptyHint =>
      'As cartas aparecem aqui depois de uma ordenação.';
  @override
  String get noCardsFoundTitle => 'Nenhuma carta encontrada';
  @override
  String get noCardsFoundHint => 'Confira a grafia ou tente outro nome.';
  @override
  String get cardsLoadFailedTitle => 'Não foi possível carregar as cartas';
  @override
  String cardsFailure(CardsFailure failure) => switch (failure) {
        CardsFailure.unauthorized => 'Sua sessão expirou. Entre novamente.',
        CardsFailure.serverUnreachable =>
          'Sem conexão com o servidor. Verifique sua internet e tente de novo.',
        CardsFailure.serverError =>
          'O servidor teve um problema. Tente novamente.',
      };
  @override
  String get signInAgain => 'Entrar novamente';

  // Machine control
  @override
  String get startResume => 'Iniciar/Continuar';
  @override
  String get stop => 'Parar';
  @override
  String get checkingMachine => 'Verificando a máquina…';
  @override
  String get controlLoadFailedTitle =>
      'Não foi possível obter o status da máquina';
  @override
  String runStateLabel(MachineRunState state) => switch (state) {
        MachineRunState.idle => 'Pronta',
        MachineRunState.running => 'Em execução',
        MachineRunState.stopped => 'Parada',
      };
  @override
  String runStateHint(MachineRunState state) => switch (state) {
        MachineRunState.idle => 'Pronta para iniciar a ordenação.',
        MachineRunState.running => 'Ordenando as cartas…',
        MachineRunState.stopped =>
          'Ordenação parada. Toque em Iniciar/Continuar para continuar.',
      };
  @override
  String controlFailure(MachineControlFailure failure) => switch (failure) {
        MachineControlFailure.unauthorized =>
          'Sua sessão expirou. Entre novamente.',
        MachineControlFailure.serverUnreachable =>
          'Sem conexão com o servidor. Verifique sua internet e tente de novo.',
        MachineControlFailure.machineOffline =>
          'A máquina está offline. Confira se está ligada e conectada ao Wi-Fi.',
        MachineControlFailure.serverError =>
          'O servidor teve um problema. Tente novamente.',
      };

  // Settings
  @override
  String get languageSection => 'Idioma';
  @override
  String get developerTools => 'Ferramentas de desenvolvimento';
  @override
  String get simulateAlerts => 'Simular alertas';

  // Alerts
  @override
  String get noAlerts => 'Nenhum alerta ainda';
  @override
  String get noAlertsHint => 'Os eventos da máquina vão aparecer aqui.';
  @override
  String get markAllRead => 'Marcar tudo como lido';
  @override
  String get clearAll => 'Limpar tudo';
  @override
  String get yourMachine => 'Sua máquina';
  @override
  String alertTitle(AlertType type) => switch (type) {
        AlertType.wifiConnected => 'Máquina conectada ao Wi-Fi',
        AlertType.wifiDisconnected => 'Máquina sem Wi-Fi',
        AlertType.batchFinished => 'Ordenação concluída',
        AlertType.jamDetected => 'Atolamento detectado',
        AlertType.doubleFeed => 'Alimentação dupla detectada',
        AlertType.connectionLost => 'Conexão perdida',
        AlertType.machineLinked => 'Máquina vinculada',
      };
  @override
  String alertMessage(MachineAlert alert) {
    final name = alert.machineName ?? yourMachine;
    return switch (alert.type) {
      AlertType.wifiConnected => '$name está online.',
      AlertType.wifiDisconnected =>
        '$name está offline. Verifique sua rede Wi-Fi.',
      AlertType.batchFinished =>
        '$name processou ${alert.cardCount ?? 0} cartas.',
      AlertType.jamDetected => '$name parou. Remova o atolamento e retome.',
      AlertType.doubleFeed => '$name puxou duas cartas ao mesmo tempo.',
      AlertType.connectionLost =>
        'Contato com $name perdido. A ordenação está pausada.',
      AlertType.machineLinked => '$name agora está vinculada à sua conta.',
    };
  }
}
