// lib/features/plant_identification/config/plant_id_config.dart
class PlantIdConfig {
  // ⚠️ IMPORTANTE: Adicione sua API key do PlantNet aqui
  // Obtenha gratuitamente em: https://my.plantnet.org/
  static const String plantNetApiKey = '2b10bwe4u45Lof4wYURX1xAO';
  
  // Configurações da API
  static const String plantNetProject = 'weurope'; // ou 'world' para cobertura global
  static const int maxResults = 5;
  static const int timeoutSeconds = 30;
  
  // Configurações de pontos
  static const int pointsHighConfidence = 50;    // >70% confiança
  static const int pointsMediumConfidence = 30;  // 40-70% confiança
  static const int pointsLowConfidence = 15;     // 20-40% confiança
  static const int pointsAttempt = 10;           // Tentativa sem identificação
  
  // Thresholds de confiança
  static const double highConfidenceThreshold = 0.7;
  static const double mediumConfidenceThreshold = 0.4;
  static const double lowConfidenceThreshold = 0.2;
  
  // Configurações de câmera
  static const double cameraFrameSize = 280.0;
  static const double cornerIndicatorSize = 30.0;
  
  // Validação da configuração
  static bool get isConfigured => plantNetApiKey != 'YOUR_PLANTNET_API_KEY_HERE';
  
  static void validateConfiguration() {
    if (!isConfigured) {
      throw Exception(
        'PlantNet API key não configurada! '
        'Adicione sua chave em PlantIdConfig.plantNetApiKey'
      );
    }
  }
}

/*
=============================================================================
🌱 GUIA DE IMPLEMENTAÇÃO - IDENTIFICAÇÃO DE PLANTAS
=============================================================================

## 📋 CHECKLIST DE IMPLEMENTAÇÃO

### 1. ✅ Arquivos Criados:
   - PlantNetService: Integração com API
   - LocalPlantKnowledge: Base de dados local
   - PlantIdentificationPage: UI principal
   - PlantResultSheet: Resultado da identificação
   - Integração no AR Experience

### 2. 🔑 CONFIGURAÇÃO NECESSÁRIA:

   a) **API Key do PlantNet:**
      - Vá para: https://my.plantnet.org/
      - Registre-se gratuitamente
      - Copie sua API key
      - Cole em PlantIdConfig.plantNetApiKey

   b) **Dependências no pubspec.yaml:**
      ```yaml
      dependencies:
        camera: ^0.10.5
        path_provider: ^2.1.1
        # (já existem no projeto)
      ```

   c) **Permissões (android/app/src/main/AndroidManifest.xml):**
      ```xml
      <uses-permission android:name="android.permission.CAMERA" />
      <uses-permission android:name="android.permission.INTERNET" />
      ```

### 3. 🔗 INTEGRAÇÃO NO APP:

   a) **No main.dart, adicionar no MultiBlocProvider:**
      ```dart
      // Adicionar se criar um BLoC para plant ID (opcional)
      ```

   b) **No app_router.dart, adicionar rota:**
      ```dart
      GoRoute(
        path: '/plant-identification',
        name: 'plant_identification',
        builder: (context, state) => const PlantIdentificationPage(),
      ),
      ```

   c) **No ar_experience_page.dart:**
      - Usar o código de integração fornecido
      - Adicionar botão "Plantas" na barra de ações
      - Implementar navegação

### 4. 🎯 PONTOS DE INTEGRAÇÃO COM GAMIFICAÇÃO:

   ```dart
   // No callback onPointsEarned do PlantResultSheet:
   void _onPointsEarned(int points) {
     // Integrar com sistema de pontos existente
     context.read<GamificationBloc>().add(
       GamificationAddPoints(
         points: points,
         category: 'plant_identification',
         description: 'Planta identificada',
       ),
     );
   }
   ```

### 5. 🌿 CUSTOMIZAÇÃO PARA OUTRAS REGIÕES:

   a) **Expandir LocalPlantKnowledge:**
      - Adicionar mais plantas na _plantDatabase
      - Incluir informações específicas da região
      - Traduzir para línguas locais

   b) **Configurar projeto PlantNet:**
      - 'weurope': Europa/Mediterrâneo
      - 'world': Global (menos preciso)
      - 'k-world-flora': Específico para algumas regiões

### 6. 📊 ANALYTICS E MÉTRICAS:

   ```dart
   // Adicionar tracking de uso:
   AppLogger.logUserAction('plant_identified', {
     'plant_name': plantName,
     'confidence': confidence,
     'location': currentLocation,
   });
   ```

### 7. 🔄 FLUXO COMPLETO:

   1. Usuário está em experiência AR
   2. Vê planta interessante no mundo real
   3. Toca botão "Plantas" 
   4. Câmera abre em modo identificação
   5. Seleciona parte da planta (folha, flor, etc.)
   6. Captura foto
   7. PlantNet API identifica
   8. App mostra informação local relevante
   9. Usuário ganha pontos
   10. Pode salvar na coleção pessoal

### 8. 🚨 TRATAMENTO DE ERROS:

   - Sem conexão → Mostrar plantas locais conhecidas
   - API indisponível → Educação geral sobre biodiversidade
   - Planta não identificada → Pontos de consolação
   - Câmera indisponível → Permitir seleção da galeria

### 9. 🎮 GAMIFICAÇÃO SUGERIDA:

   - Badge "Botânico": 10 plantas identificadas
   - Badge "Especialista Local": 5 plantas nativas
   - Badge "Explorador Verde": Plantas de todas as categorias
   - Streak: Identificações em dias consecutivos
   - Leaderboard: Plantas únicas descobertas

### 10. 📱 TESTES:

   a) **Teste com API:**
      ```dart
      // Teste básico
      final service = PlantNetService(apiKey: 'sua_chave');
      final result = await service.identifyPlant(
        imageFile: imagemTeste,
        organ: PlantOrgan.leaf,
      );
      print('Resultado: ${result.bestMatch?.species.displayName}');
      ```

   b) **Teste sem API:**
      - Verificar fallback educativo
      - Confirmar pontos de consolação
      - Validar UI sem conexão

=============================================================================
💡 DICAS PARA MELHORES RESULTADOS:
=============================================================================

1. **Fotografias:**
   - Luz natural (evitar flash)
   - Fundo contrastante
   - Folha/flor inteira no enquadramento
   - Evitar sombras e reflexos

2. **Seleção de Órgão:**
   - Folhas: Melhor para árvores e arbustos
   - Flores: Excelente quando disponíveis
   - Frutos: Bom para identificação de frutíferas
   - Casca: Para árvores grandes

3. **Plantas Locais:**
   - Expandir database com espécies da região
   - Incluir nomes em línguas locais
   - Adicionar fotos de referência locais
   - Contexto cultural e usos tradicionais

=============================================================================
🚀 PRÓXIMOS PASSOS:
=============================================================================

1. ✅ Implementar código fornecido
2. 🔑 Configurar API key
3. 📱 Testar com plantas reais
4. 🌍 Expandir knowledge base local
5. 🎮 Integrar com sistema de pontos
6. 📊 Adicionar analytics
7. 🔄 Coletar feedback dos usuários
8. 🌱 Iteração e melhorias

=============================================================================
*/