import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:app_web_view/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  PullToRefreshController? _pullToRefreshController;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _progress = 0;
  bool _canGoBack = false;  // Adicionado para rastrear se podemos voltar

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    verticalScrollBarEnabled: true,
    horizontalScrollBarEnabled: false,
    domStorageEnabled: true,
    databaseEnabled: true,
    useShouldOverrideUrlLoading: true,
    supportZoom: false,
    geolocationEnabled: true,
    thirdPartyCookiesEnabled: true,
    transparentBackground: false,
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119 Safari/537.36',
  );

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.blue),
      onRefresh: () => _webViewController?.reload(),
    );
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.storage,
      Permission.accessMediaLocation,
      Permission.manageExternalStorage,
      Permission.locationWhenInUse,
    ].request();

    if (statuses[Permission.locationWhenInUse]!.isPermanentlyDenied) {
      _showPermissionPermanentlyDeniedDialog();
    }
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissões Necessárias'),
        content: const Text('Para funcionar corretamente, o app precisa de permissões de armazenamento e localização.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }

  Future<Directory> _getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Tente acessar diretamente a pasta "Download" externa
        Directory? directory;
        
        // Primeiro, tente o caminho direto para a pasta Download
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (await directory.exists()) {
            return directory;
          }
        } catch (e) {
          // Ignora erro e tenta outro método
        }
        
        // Tente encontrar o caminho através de getExternalStorageDirectory
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final String externalPath = externalDir.path;
            // Encontra a pasta Android no caminho
            final int androidPos = externalPath.indexOf('Android');
            if (androidPos > 0) {
              final String rootPath = externalPath.substring(0, androidPos);
              directory = Directory('${rootPath}Download');
              
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }
              return directory;
            }
          }
        } catch (e) {
          debugPrint('Erro ao encontrar diretório externo: $e');
        }
        
        // Se ainda não encontrou, tente outros caminhos conhecidos
        for (final path in [
          '/storage/sdcard0/Download',
          '/storage/sdcard1/Download',
          '/sdcard/Download',
          '/mnt/sdcard/Download'
        ]) {
          try {
            directory = Directory(path);
            if (await directory.exists()) {
              return directory;
            } else {
              await directory.create(recursive: true);
              return directory;
            }
          } catch (e) {
            // Tente o próximo caminho
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao encontrar diretório de downloads: $e');
    }
    
    // Fallback para o diretório de downloads padrão
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${appDir.path}/Downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  Future<void> _saveFile(List<int> bytes, String filename) async {
    try {
      // Solicitar permissões de armazenamento mais abrangentes
      if (!await Permission.manageExternalStorage.isGranted) {
        await Permission.manageExternalStorage.request();
      }

      final downloadsDir = await _getDownloadsDirectory();
      debugPrint('Salvando em: ${downloadsDir.path}');

      final file = File('${downloadsDir.path}/$filename');
      await file.writeAsBytes(List<int>.from(bytes), flush: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arquivo salvo em: ${file.path}'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Abrir',
              onPressed: () async {
                if (await file.exists()) {
                  // Use o sistema de compartilhamento para permitir que o usuário escolha
                  // qual aplicativo deseja usar para abrir o PDF
                  await _openFileWithIntent(file.path);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _openFileWithIntent(String filePath) async {
    try {
      // Em vez de tentar abrir o arquivo diretamente, vamos compartilhá-lo
      final file = File(filePath);
      if (await file.exists()) {
        // Use o plugin share_plus para compartilhar o arquivo
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Abrir com:',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arquivo não encontrado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir o arquivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _injectDownloadScript() async {
    try {
      await _webViewController?.evaluateJavascript(
        source: '''
          if (typeof window.downloadBlob !== 'function') {
            window.downloadBlob = function(blob, filename) {
              return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onload = function() {
                  const base64 = reader.result.split(',')[1];
                  window.flutter_inappwebview.callHandler('handleDownload', base64, filename)
                    .then(resolve)
                    .catch(reject);
                };
                reader.onerror = reject;
                reader.readAsDataURL(blob);
              });
            };
          }
        ''',
      );
    } catch (e) {
      debugPrint('Erro ao injetar script: $e');
    }
  }

  // Função para verificar se o WebView pode voltar
  Future<bool> _handleBackButton() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      _webViewController!.goBack();
      return false; // Impede o comportamento padrão de voltar (fechar o app)
    }
    return true; // Permite o comportamento padrão de voltar (fechar o app)
  }

  @override
  Widget build(BuildContext context) {
    return PopScope( // Use PopScope (Flutter 3.12+) ou WillPopScope para versões anteriores
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final bool canGoBack = await _handleBackButton();
        if (!canGoBack) {
          // Se o WebView puder voltar, já foi tratado em _handleBackButton
          return;
        }
        
        // Se não puder voltar no WebView, permita o comportamento padrão
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
                initialSettings: _settings,
                pullToRefreshController: _pullToRefreshController,
                onWebViewCreated: (controller) async {
                  _webViewController = controller;
                  await _injectDownloadScript();

                  controller.addJavaScriptHandler(
                    handlerName: 'handleDownload',
                    callback: (args) async {
                      if (args.length >= 2) {
                        await _saveFile(base64Decode(args[0]), args[1]);
                      }
                    },
                  );
                },
                onLoadStart: (_, __) => setState(() => _isLoading = true),
                onLoadStop: (_, __) async {
                  _pullToRefreshController?.endRefreshing();
                  setState(() => _isLoading = false);
                  
                  // Atualiza o estado de "pode voltar"
                  if (_webViewController != null) {
                    _canGoBack = await _webViewController!.canGoBack();
                    setState(() {});
                  }
                  
                  await _injectDownloadScript();
                },
                onProgressChanged: (_, progress) {
                  setState(() => _progress = progress / 100);
                },
                onReceivedHttpError: (_, __, errorResponse) {
                  _pullToRefreshController?.endRefreshing();

                  if (errorResponse.statusCode == 401) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Usuário ou senha inválidos'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _hasError = true;
                    _errorMessage = 'Erro ${errorResponse.statusCode}';
                  });
                },
                shouldOverrideUrlLoading: (_, navigationAction) async {
                  final uri = navigationAction.request.url;
                  if (uri?.toString().contains('new-api.urbis.cc/auth/user') ?? false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Credenciais inválidas'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onDownloadStartRequest: (_, request) async {
                  if (!await Permission.storage.isGranted || 
                      !await Permission.manageExternalStorage.isGranted) {
                    final storageStatus = await Permission.storage.request();
                    final manageStatus = await Permission.manageExternalStorage.request();
                    
                    if (!storageStatus.isGranted || !manageStatus.isGranted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Permissões de armazenamento necessárias'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }

                  try {
                    final filename = request.suggestedFilename ?? 'download_${DateTime.now().millisecondsSinceEpoch}.pdf';

                    if (request.url.toString().startsWith('blob:')) {
                      await _webViewController?.evaluateJavascript(
                        source: '''
                          (function() {
                            const xhr = new XMLHttpRequest();
                            xhr.open('GET', '${request.url}');
                            xhr.responseType = 'blob';
                            xhr.onload = function() {
                              if (this.status === 200) {
                                window.downloadBlob(this.response, '$filename')
                                  .catch(e => console.error('Download error:', e));
                              }
                            };
                            xhr.onerror = function() {
                              console.error('XHR error:', this.statusText);
                            };
                            xhr.send();
                          })();
                        ''',
                      );
                      return;
                    }

                    final httpClient = HttpClient();
                    final httpRequest = await httpClient.getUrl(request.url);
                    final httpResponse = await httpRequest.close();
                    final bytes = await httpResponse.fold<List<int>>(<int>[], (previous, element) => previous..addAll(element));

                    await _saveFile(bytes, filename);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Falha no download: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                onGeolocationPermissionsShowPrompt: (controller, origin) async {
                  if (await Permission.locationWhenInUse.isGranted) {
                    return GeolocationPermissionShowPromptResponse(
                      origin: origin,
                      allow: true,
                      retain: true,
                    );
                  }
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: false,
                    retain: false,
                  );
                },
                // Adiciona o evento para verificar quando o histórico de navegação muda
                onUpdateVisitedHistory: (controller, url, isReload) async {
                  if (_webViewController != null) {
                    _canGoBack = await _webViewController!.canGoBack();
                    setState(() {});
                  }
                },
              ),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                ),
              if (_hasError)
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 50),
                          const SizedBox(height: 16),
                          Text(_errorMessage, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _hasError = false);
                              _webViewController?.reload();
                            },
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}