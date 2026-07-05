#!/usr/bin/env python3
"""
Generate Localizable_<lang>.strings for es, de, it, pt, ja, ko, zh-Hans
from English base and French reference. Uses phrase-level translation (French -> other).
Run: python3 Scripts/gen_all_localizations.py
Optional: add Resources/translations/fr_phrase_map.json to extend translations:
  { "French phrase": { "es": "...", "de": "...", "it": "...", "pt": "...", "ja": "...", "ko": "...", "zh-Hans": "..." }, ... }
"""
import os
import re
import json

BASE = os.path.join(os.path.dirname(__file__), "..", "Resources")
EN_FILE = os.path.join(BASE, "Localizable.strings")
FR_FILE = os.path.join(BASE, "Localizable_fr.strings")
TRANSLATIONS_DIR = os.path.join(BASE, "translations")
PHRASE_MAP_JSON = os.path.join(TRANSLATIONS_DIR, "fr_phrase_map.json")

def parse(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    return list(re.findall(r'"([^"]+)"\s*=\s*"(.*)"\s*;', content))

def escape_string(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")

# French phrase -> { es, de, it, pt, ja, ko, zh-Hans }. Fallback to EN if missing.
def load_fr_to_langs():
    return {
        "Triply": {"es": "Triply", "de": "Triply", "it": "Triply", "pt": "Triply", "ja": "Triply", "ko": "트리플리", "zh-Hans": "Triply"},
        "Version 1.0.0": {"es": "Versión 1.0.0", "de": "Version 1.0.0", "it": "Versione 1.0.0", "pt": "Versão 1.0.0", "ja": "バージョン 1.0.0", "ko": "버전 1.0.0", "zh-Hans": "版本 1.0.0"},
        "Planifiez vos voyages en toute simplicité. Organisez les destinations, créez des itinéraires et suivez votre budget en un seul endroit.": {
            "es": "Planifica tus viajes con facilidad. Organiza destinos, crea itinerarios y controla tu presupuesto en un solo lugar.",
            "de": "Planen Sie Ihre Reisen ganz einfach. Ziele organisieren, Routen erstellen und Budget an einem Ort verwalten.",
            "it": "Pianifica i tuoi viaggi con facilità. Organizza destinazioni, itinerari e budget in un unico posto.",
            "pt": "Planeie as suas viagens com facilidade. Organize destinos, itinerários e orçamento num só lugar.",
            "ja": "旅行を簡単に計画。目的地・旅程・予算を一か所で管理。",
            "ko": "여행을 쉽게 계획하세요. 목적지, 일정, 예산을 한곳에서 관리하세요.",
            "zh-Hans": "轻松规划旅行。在一处管理目的地、行程与预算。",
        },
        "Itinero": {"es": "Itinero", "de": "Itinero", "it": "Itinero", "pt": "Itinero", "ja": "Itinero", "ko": "Itinero", "zh-Hans": "Itinero"},
        "Planifiez vos voyages": {"es": "Planifica tus viajes", "de": "Planen Sie Ihre Reisen", "it": "Pianifica i tuoi viaggi", "pt": "Planeie as suas viagens", "ja": "旅行を計画", "ko": "여행 계획하기", "zh-Hans": "规划您的旅行"},
        "Enregistrer": {"es": "Guardar", "de": "Speichern", "it": "Salva", "pt": "Guardar", "ja": "保存", "ko": "저장", "zh-Hans": "保存"},
        "Annuler": {"es": "Cancelar", "de": "Abbrechen", "it": "Annulla", "pt": "Cancelar", "ja": "キャンセル", "ko": "취소", "zh-Hans": "取消"},
        "Modifier": {"es": "Editar", "de": "Bearbeiten", "it": "Modifica", "pt": "Editar", "ja": "編集", "ko": "편집", "zh-Hans": "编辑"},
        "Supprimer": {"es": "Eliminar", "de": "Löschen", "it": "Elimina", "pt": "Eliminar", "ja": "削除", "ko": "삭제", "zh-Hans": "删除"},
        "Retirer": {"es": "Quitar", "de": "Entfernen", "it": "Rimuovi", "pt": "Remover", "ja": "削除", "ko": "제거", "zh-Hans": "移除"},
        "Rechercher": {"es": "Buscar", "de": "Suchen", "it": "Cerca", "pt": "Pesquisar", "ja": "検索", "ko": "검색", "zh-Hans": "搜索"},
        "Filtrer": {"es": "Filtrar", "de": "Filtern", "it": "Filtra", "pt": "Filtrar", "ja": "フィルター", "ko": "필터", "zh-Hans": "筛选"},
        "Partager": {"es": "Compartir", "de": "Teilen", "it": "Condividi", "pt": "Partilhar", "ja": "共有", "ko": "공유", "zh-Hans": "分享"},
        "Terminé": {"es": "Listo", "de": "Fertig", "it": "Fatto", "pt": "Concluído", "ja": "完了", "ko": "완료", "zh-Hans": "完成"},
        "Nom": {"es": "Nombre", "de": "Name", "it": "Nome", "pt": "Nome", "ja": "名前", "ko": "이름", "zh-Hans": "名称"},
        "Ajouter": {"es": "Añadir", "de": "Hinzufügen", "it": "Aggiungi", "pt": "Adicionar", "ja": "追加", "ko": "추가", "zh-Hans": "添加"},
        "Fermer": {"es": "Cerrar", "de": "Schließen", "it": "Chiudi", "pt": "Fechar", "ja": "閉じる", "ko": "닫기", "zh-Hans": "关闭"},
        "Retour": {"es": "Atrás", "de": "Zurück", "it": "Indietro", "pt": "Voltar", "ja": "戻る", "ko": "뒤로", "zh-Hans": "返回"},
        "Suivant": {"es": "Siguiente", "de": "Weiter", "it": "Avanti", "pt": "Seguinte", "ja": "次へ", "ko": "다음", "zh-Hans": "下一步"},
        "Continuer": {"es": "Continuar", "de": "Fortsetzen", "it": "Continua", "pt": "Continuar", "ja": "続ける", "ko": "계속", "zh-Hans": "继续"},
        "Oui": {"es": "Sí", "de": "Ja", "it": "Sì", "pt": "Sim", "ja": "はい", "ko": "예", "zh-Hans": "是"},
        "Non": {"es": "No", "de": "Nein", "it": "No", "pt": "Não", "ja": "いいえ", "ko": "아니요", "zh-Hans": "否"},
        "OK": {"es": "OK", "de": "OK", "it": "OK", "pt": "OK", "ja": "OK", "ko": "확인", "zh-Hans": "确定"},
        "Chargement…": {"es": "Cargando…", "de": "Laden…", "it": "Caricamento…", "pt": "A carregar…", "ja": "読み込み中…", "ko": "로딩 중…", "zh-Hans": "加载中…"},
        "Erreur": {"es": "Error", "de": "Fehler", "it": "Errore", "pt": "Erro", "ja": "エラー", "ko": "오류", "zh-Hans": "错误"},
        "Succès": {"es": "Éxito", "de": "Erfolg", "it": "Successo", "pt": "Sucesso", "ja": "成功", "ko": "성공", "zh-Hans": "成功"},
        "Mes voyages": {"es": "Mis viajes", "de": "Meine Reisen", "it": "I miei viaggi", "pt": "As minhas viagens", "ja": "マイ旅行", "ko": "내 여행", "zh-Hans": "我的旅行"},
        "Ajouter un voyage": {"es": "Añadir viaje", "de": "Reise hinzufügen", "it": "Aggiungi viaggio", "pt": "Adicionar viagem", "ja": "旅行を追加", "ko": "여행 추가", "zh-Hans": "添加旅行"},
        "Aucun voyage": {"es": "Sin viajes", "de": "Noch keine Reisen", "it": "Nessun viaggio", "pt": "Sem viagens", "ja": "旅行がありません", "ko": "여행 없음", "zh-Hans": "暂无旅行"},
        "Commencez à planifier votre prochaine aventure !": {"es": "¡Empieza a planificar tu próxima aventura!", "de": "Beginnen Sie mit der Planung Ihres nächsten Abenteuers!", "it": "Inizia a pianificare la tua prossima avventura!", "pt": "Comece a planear a sua próxima aventura!", "ja": "次の冒険の計画を始めましょう！", "ko": "다음 여행을 계획해 보세요!", "zh-Hans": "开始规划您的下一次旅行！"},
        "Commencez à planifier votre prochaine aventure en créant votre premier voyage.": {"es": "Empieza a planificar tu próxima aventura creando tu primer viaje.", "de": "Beginnen Sie mit der Planung, indem Sie Ihre erste Reise erstellen.", "it": "Inizia creando il tuo primo viaggio.", "pt": "Crie a sua primeira viagem para começar.", "ja": "最初の旅行を作成して計画を始めましょう。", "ko": "첫 여행을 만들어 보세요.", "zh-Hans": "创建您的第一次旅行以开始规划。"},
        "Créer votre premier voyage": {"es": "Crear tu primer viaje", "de": "Erste Reise erstellen", "it": "Crea il tuo primo viaggio", "pt": "Criar a sua primeira viagem", "ja": "最初の旅行を作成", "ko": "첫 여행 만들기", "zh-Hans": "创建您的第一次旅行"},
        "Nouveau voyage": {"es": "Nuevo viaje", "de": "Neue Reise", "it": "Nuovo viaggio", "pt": "Nova viagem", "ja": "新しい旅行", "ko": "새 여행", "zh-Hans": "新旅行"},
        "Modifier le voyage": {"es": "Editar viaje", "de": "Reise bearbeiten", "it": "Modifica viaggio", "pt": "Editar viagem", "ja": "旅行を編集", "ko": "여행 편집", "zh-Hans": "编辑旅行"},
        "Supprimer le voyage": {"es": "Eliminar viaje", "de": "Reise löschen", "it": "Elimina viaggio", "pt": "Eliminar viagem", "ja": "旅行を削除", "ko": "여행 삭제", "zh-Hans": "删除旅行"},
        "Détails du voyage": {"es": "Detalles del viaje", "de": "Reisedetails", "it": "Dettagli viaggio", "pt": "Detalhes da viagem", "ja": "旅行の詳細", "ko": "여행 세부정보", "zh-Hans": "旅行详情"},
        "Nom du voyage": {"es": "Nombre del viaje", "de": "Reisename", "it": "Nome del viaggio", "pt": "Nome da viagem", "ja": "旅行名", "ko": "여행 이름", "zh-Hans": "旅行名称"},
        "Date de début": {"es": "Fecha de inicio", "de": "Startdatum", "it": "Data di inizio", "pt": "Data de início", "ja": "開始日", "ko": "시작일", "zh-Hans": "开始日期"},
        "Date de fin": {"es": "Fecha de fin", "de": "Enddatum", "it": "Data di fine", "pt": "Data de fim", "ja": "終了日", "ko": "종료일", "zh-Hans": "结束日期"},
        "Notes": {"es": "Notas", "de": "Notizen", "it": "Note", "pt": "Notas", "ja": "メモ", "ko": "메모", "zh-Hans": "备注"},
        "Budget": {"es": "Presupuesto", "de": "Budget", "it": "Budget", "pt": "Orçamento", "ja": "予算", "ko": "예산", "zh-Hans": "预算"},
        "Catégorie": {"es": "Categoría", "de": "Kategorie", "it": "Categoria", "pt": "Categoria", "ja": "カテゴリ", "ko": "카테고리", "zh-Hans": "分类"},
        "Durée": {"es": "Duración", "de": "Dauer", "it": "Durata", "pt": "Duração", "ja": "期間", "ko": "기간", "zh-Hans": "时长"},
        "jours": {"es": "días", "de": "Tage", "it": "giorni", "pt": "dias", "ja": "日", "ko": "일", "zh-Hans": "天"},
        "jour": {"es": "día", "de": "Tag", "it": "giorno", "pt": "dia", "ja": "日", "ko": "일", "zh-Hans": "天"},
        "Voyages en cours": {"es": "Viajes actuales", "de": "Aktuelle Reisen", "it": "Viaggi in corso", "pt": "Viagens atuais", "ja": "現在の旅行", "ko": "현재 여행", "zh-Hans": "当前旅行"},
        "À venir": {"es": "Próximos", "de": "Kommend", "it": "In programma", "pt": "Próximas", "ja": "予定", "ko": "예정", "zh-Hans": "即将到来"},
        "Voyages passés": {"es": "Viajes pasados", "de": "Vergangene Reisen", "it": "Viaggi passati", "pt": "Viagens passadas", "ja": "過去の旅行", "ko": "과거 여행", "zh-Hans": "过去旅行"},
        "Voyages au total": {"es": "Total de viajes", "de": "Reisen gesamt", "it": "Totale viaggi", "pt": "Total de viagens", "ja": "旅行合計", "ko": "총 여행", "zh-Hans": "旅行总数"},
        "Budget total": {"es": "Presupuesto total", "de": "Gesamtbudget", "it": "Budget totale", "pt": "Orçamento total", "ja": "合計予算", "ko": "총 예산", "zh-Hans": "总预算"},
        "En cours": {"es": "Activo", "de": "Aktiv", "it": "Attivo", "pt": "Ativo", "ja": "進行中", "ko": "활성", "zh-Hans": "进行中"},
        "Passé": {"es": "Pasado", "de": "Vergangen", "it": "Passato", "pt": "Passado", "ja": "過去", "ko": "과거", "zh-Hans": "过去"},
        "lieux": {"es": "lugares", "de": "Orte", "it": "luoghi", "pt": "lugares", "ja": "場所", "ko": "장소", "zh-Hans": "地点"},
        "Rechercher voyages, lieux…": {"es": "Buscar viajes, lugares…", "de": "Reisen, Orte suchen…", "it": "Cerca viaggi, luoghi…", "pt": "Pesquisar viagens, lugares…", "ja": "旅行・場所を検索…", "ko": "여행, 장소 검색…", "zh-Hans": "搜索旅行、地点…"},
        "Optimiser le voyage": {"es": "Optimizar viaje", "de": "Reise optimieren", "it": "Ottimizza viaggio", "pt": "Otimizar viagem", "ja": "旅行を最適化", "ko": "여행 최적화", "zh-Hans": "优化旅行"},
        "Exporter le voyage": {"es": "Exportar viaje", "de": "Reise exportieren", "it": "Esporta viaggio", "pt": "Exportar viagem", "ja": "旅行をエクスポート", "ko": "여행 내보내기", "zh-Hans": "导出旅行"},
        "Rappels": {"es": "Recordatorios", "de": "Erinnerungen", "it": "Promemoria", "pt": "Lembretes", "ja": "リマインダー", "ko": "알림", "zh-Hans": "提醒"},
        "Général": {"es": "General", "de": "Allgemein", "it": "Generale", "pt": "Geral", "ja": "一般", "ko": "일반", "zh-Hans": "常规"},
        "Aventure": {"es": "Aventura", "de": "Abenteuer", "it": "Avventura", "pt": "Aventura", "ja": "アドベンチャー", "ko": "모험", "zh-Hans": "冒险"},
        "Professionnel": {"es": "Negocios", "de": "Geschäftlich", "it": "Lavoro", "pt": "Negócios", "ja": "ビジネス", "ko": "비즈니스", "zh-Hans": "商务"},
        "Détente": {"es": "Relajación", "de": "Entspannung", "it": "Relax", "pt": "Relaxamento", "ja": "リラックス", "ko": "휴양", "zh-Hans": "休闲"},
        "Famille": {"es": "Familia", "de": "Familie", "it": "Famiglia", "pt": "Família", "ja": "家族", "ko": "가족", "zh-Hans": "家庭"},
        "Tout": {"es": "Todos", "de": "Alle", "it": "Tutti", "pt": "Todos", "ja": "すべて", "ko": "전체", "zh-Hans": "全部"},
        "Destinations": {"es": "Destinos", "de": "Reiseziele", "it": "Destinazioni", "pt": "Destinos", "ja": "目的地", "ko": "목적지", "zh-Hans": "目的地"},
        "Ajouter une destination": {"es": "Añadir destino", "de": "Reiseziel hinzufügen", "it": "Aggiungi destinazione", "pt": "Adicionar destino", "ja": "目的地を追加", "ko": "목적지 추가", "zh-Hans": "添加目的地"},
        "Nom de la destination": {"es": "Nombre del destino", "de": "Reisezielname", "it": "Nome destinazione", "pt": "Nome do destino", "ja": "目的地名", "ko": "목적지 이름", "zh-Hans": "目的地名称"},
        "Adresse": {"es": "Dirección", "de": "Adresse", "it": "Indirizzo", "pt": "Morada", "ja": "住所", "ko": "주소", "zh-Hans": "地址"},
        "Aucune destination ajoutée": {"es": "Sin destinos añadidos", "de": "Noch keine Reiseziele", "it": "Nessuna destinazione", "pt": "Sem destinos adicionados", "ja": "目的地がありません", "ko": "추가된 목적지 없음", "zh-Hans": "暂无目的地"},
        "Rechercher des destinations": {"es": "Buscar destinos", "de": "Reiseziele suchen", "it": "Cerca destinazioni", "pt": "Pesquisar destinos", "ja": "目的地を検索", "ko": "목적지 검색", "zh-Hans": "搜索目的地"},
        "Réglages": {"es": "Ajustes", "de": "Einstellungen", "it": "Impostazioni", "pt": "Definições", "ja": "設定", "ko": "설정", "zh-Hans": "设置"},
        "Langue": {"es": "Idioma", "de": "Sprache", "it": "Lingua", "pt": "Idioma", "ja": "言語", "ko": "언어", "zh-Hans": "语言"},
        "Devise": {"es": "Moneda", "de": "Währung", "it": "Valuta", "pt": "Moeda", "ja": "通貨", "ko": "통화", "zh-Hans": "货币"},
        "Thème": {"es": "Tema", "de": "Design", "it": "Tema", "pt": "Tema", "ja": "テーマ", "ko": "테마", "zh-Hans": "主题"},
        "À propos": {"es": "Acerca de", "de": "Über", "it": "Informazioni", "pt": "Sobre", "ja": "について", "ko": "정보", "zh-Hans": "关于"},
        "Préférences": {"es": "Preferencias", "de": "Einstellungen", "it": "Preferenze", "pt": "Preferências", "ja": "設定", "ko": "환경설정", "zh-Hans": "偏好设置"},
        "Total": {"es": "Total", "de": "Gesamt", "it": "Totale", "pt": "Total", "ja": "合計", "ko": "합계", "zh-Hans": "总计"},
        "Montant": {"es": "Cantidad", "de": "Betrag", "it": "Importo", "pt": "Valor", "ja": "金額", "ko": "금액", "zh-Hans": "金额"},
        "Date": {"es": "Fecha", "de": "Datum", "it": "Data", "pt": "Data", "ja": "日付", "ko": "날짜", "zh-Hans": "日期"},
        "Dépenses": {"es": "Gastos", "de": "Ausgaben", "it": "Spese", "pt": "Despesas", "ja": "支出", "ko": "경비", "zh-Hans": "费用"},
        "Ajouter une dépense": {"es": "Añadir gasto", "de": "Ausgabe hinzufügen", "it": "Aggiungi spesa", "pt": "Adicionar despesa", "ja": "支出を追加", "ko": "경비 추가", "zh-Hans": "添加费用"},
        "Reçu": {"es": "Recibo", "de": "Beleg", "it": "Ricevuta", "pt": "Recibo", "ja": "領収書", "ko": "영수증", "zh-Hans": "收据"},
        "Scanner un reçu": {"es": "Escanear recibo", "de": "Beleg scannen", "it": "Scansiona ricevuta", "pt": "Digitalizar recibo", "ja": "領収書をスキャン", "ko": "영수증 스캔", "zh-Hans": "扫描收据"},
        "Supprimer le reçu": {"es": "Eliminar recibo", "de": "Beleg entfernen", "it": "Rimuovi ricevuta", "pt": "Remover recibo", "ja": "領収書を削除", "ko": "영수증 제거", "zh-Hans": "移除收据"},
        "Liste d'emballage": {"es": "Lista de equipaje", "de": "Packliste", "it": "Lista bagaglio", "pt": "Lista de bagagem", "ja": "荷物リスト", "ko": "짐 목록", "zh-Hans": "打包清单"},
        "Ajouter un article": {"es": "Añadir artículo", "de": "Artikel hinzufügen", "it": "Aggiungi articolo", "pt": "Adicionar item", "ja": "アイテムを追加", "ko": "항목 추가", "zh-Hans": "添加物品"},
        "Suggestions": {"es": "Sugerencias", "de": "Vorschläge", "it": "Suggerimenti", "pt": "Sugestões", "ja": "提案", "ko": "제안", "zh-Hans": "建议"},
        "Emballé": {"es": "Empacado", "de": "Gepackt", "it": "Imballato", "pt": "Embalado", "ja": "梱包済み", "ko": "챙김", "zh-Hans": "已打包"},
        "Non emballé": {"es": "Sin empaquetar", "de": "Nicht gepackt", "it": "Non imballato", "pt": "Não embalado", "ja": "未梱包", "ko": "미챙김", "zh-Hans": "未打包"},
        "Aucun article": {"es": "Sin artículos", "de": "Keine Artikel", "it": "Nessun articolo", "pt": "Sem itens", "ja": "アイテムがありません", "ko": "항목 없음", "zh-Hans": "暂无物品"},
        "Heure": {"es": "Hora", "de": "Uhrzeit", "it": "Ora", "pt": "Hora", "ja": "時間", "ko": "시간", "zh-Hans": "时间"},
        "Lieu": {"es": "Lugar", "de": "Ort", "it": "Luogo", "pt": "Local", "ja": "場所", "ko": "장소", "zh-Hans": "地点"},
        "Description": {"es": "Descripción", "de": "Beschreibung", "it": "Descrizione", "pt": "Descrição", "ja": "説明", "ko": "설명", "zh-Hans": "描述"},
        "Réservé": {"es": "Reservado", "de": "Gebucht", "it": "Prenotato", "pt": "Reservado", "ja": "予約済み", "ko": "예약됨", "zh-Hans": "已预订"},
        "Référence": {"es": "Referencia", "de": "Referenz", "it": "Riferimento", "pt": "Referência", "ja": "参照", "ko": "참조", "zh-Hans": "参考"},
        "Rappel": {"es": "Recordatorio", "de": "Erinnerung", "it": "Promemoria", "pt": "Lembrete", "ja": "リマインダー", "ko": "알림", "zh-Hans": "提醒"},
        "Choisir la devise": {"es": "Elegir moneda", "de": "Währung wählen", "it": "Scegli valuta", "pt": "Escolher moeda", "ja": "通貨を選択", "ko": "통화 선택", "zh-Hans": "选择货币"},
        "Convertisseur": {"es": "Conversor", "de": "Währungsrechner", "it": "Convertitore", "pt": "Conversor", "ja": "通貨換算", "ko": "환율 변환", "zh-Hans": "货币转换"},
        "De": {"es": "De", "de": "Von", "it": "Da", "pt": "De", "ja": "から", "ko": "에서", "zh-Hans": "从"},
        "Vers": {"es": "A", "de": "Nach", "it": "A", "pt": "Para", "ja": "へ", "ko": "로", "zh-Hans": "到"},
        "Convertir": {"es": "Convertir", "de": "Umrechnen", "it": "Converti", "pt": "Converter", "ja": "変換", "ko": "변환", "zh-Hans": "转换"},
        "Taux": {"es": "Tipo de cambio", "de": "Kurs", "it": "Tasso", "pt": "Taxa", "ja": "為替レート", "ko": "환율", "zh-Hans": "汇率"},
        "Dernière mise à jour": {"es": "Última actualización", "de": "Zuletzt aktualisiert", "it": "Ultimo aggiornamento", "pt": "Última atualização", "ja": "最終更新", "ko": "마지막 업데이트", "zh-Hans": "最后更新"},
        "Résultat": {"es": "Resultado", "de": "Ergebnis", "it": "Risultato", "pt": "Resultado", "ja": "結果", "ko": "결과", "zh-Hans": "结果"},
        "Actualiser les taux": {"es": "Actualizar tipos", "de": "Kurse aktualisieren", "it": "Aggiorna tassi", "pt": "Atualizar taxas", "ja": "レートを更新", "ko": "환율 새로고침", "zh-Hans": "刷新汇率"},
        "Mise à jour": {"es": "Actualizado", "de": "Aktualisiert", "it": "Aggiornato", "pt": "Atualizado", "ja": "更新済み", "ko": "업데이트됨", "zh-Hans": "已更新"},
    }

# English phrase -> { fr, es, de, it, pt, ja, ko, zh-Hans } for strings that appear in English in FR file
def load_en_phrase_map_builtin():
    return {
        "AI Expense Insights": {"fr": "Insights dépenses IA", "es": "Insights de gastos IA", "de": "KI-Ausgaben-Insights", "it": "Insights spese IA", "pt": "Insights de despesas IA", "ja": "AI支出インサイト", "ko": "AI 경비 인사이트", "zh-Hans": "AI 费用洞察"},
        "AI Tip: Set a budget to get personalized spending insights": {"fr": "Conseil IA : Définissez un budget pour des insights personnalisés", "es": "Consejo IA: Establece un presupuesto para insights personalizados", "de": "KI-Tipp: Setzen Sie ein Budget für personalisierte Einblicke", "it": "Suggerimento IA: Imposta un budget per insights personalizzati", "pt": "Dica IA: Defina um orçamento para insights personalizados", "ja": "AIのヒント：予算を設定してパーソナライズされた分析を", "ko": "AI 팁: 맞춤 지출 인사이트를 위해 예산을 설정하세요", "zh-Hans": "AI 提示：设置预算以获取个性化支出洞察"},
        "AI Tip: You've used \\(Int(percentage))% of your budget. Consider reviewing expenses.": {"fr": "Conseil IA : Vous avez utilisé \\(Int(percentage))% du budget. Pensez à revoir les dépenses.", "es": "Consejo IA: Has usado \\(Int(percentage))% de tu presupuesto. Revisa los gastos.", "de": "KI-Tipp: Sie haben \\(Int(percentage))% Ihres Budgets verbraucht. Prüfen Sie die Ausgaben.", "it": "Suggerimento IA: Hai usato \\(Int(percentage))% del budget. Rivedi le spese.", "pt": "Dica IA: Você usou \\(Int(percentage))% do orçamento. Revise as despesas.", "ja": "AIのヒント：予算の\\(Int(percentage))%を使用しました。支出を確認してください。", "ko": "AI 팁: 예산의 \\(Int(percentage))%를 사용했습니다. 경비를 검토하세요.", "zh-Hans": "AI 提示：您已使用预算的 \\(Int(percentage))%。请查看支出。"},
        "Budget Usage": {"fr": "Utilisation du budget", "es": "Uso del presupuesto", "de": "Budgetverbrauch", "it": "Uso del budget", "pt": "Uso do orçamento", "ja": "予算の使用", "ko": "예산 사용량", "zh-Hans": "预算使用"},
        "Remaining: \\(settingsManager.formatAmount(remaining))": {"fr": "Restant : \\(settingsManager.formatAmount(remaining))", "es": "Restante: \\(settingsManager.formatAmount(remaining))", "de": "Verbleibend: \\(settingsManager.formatAmount(remaining))", "it": "Rimanente: \\(settingsManager.formatAmount(remaining))", "pt": "Restante: \\(settingsManager.formatAmount(remaining))", "ja": "残り: \\(settingsManager.formatAmount(remaining))", "ko": "남음: \\(settingsManager.formatAmount(remaining))", "zh-Hans": "剩余：\\(settingsManager.formatAmount(remaining))"},
        "Spent: \\(settingsManager.formatAmount(totalExpenses))": {"fr": "Dépensé : \\(settingsManager.formatAmount(totalExpenses))", "es": "Gastado: \\(settingsManager.formatAmount(totalExpenses))", "de": "Ausgegeben: \\(settingsManager.formatAmount(totalExpenses))", "it": "Speso: \\(settingsManager.formatAmount(totalExpenses))", "pt": "Gasto: \\(settingsManager.formatAmount(totalExpenses))", "ja": "支出: \\(settingsManager.formatAmount(totalExpenses))", "ko": "지출: \\(settingsManager.formatAmount(totalExpenses))", "zh-Hans": "已花费：\\(settingsManager.formatAmount(totalExpenses))"},
        "AI Insights": {"fr": "Insights IA", "es": "Insights IA", "de": "KI-Insights", "it": "Insights IA", "pt": "Insights IA", "ja": "AIインサイト", "ko": "AI 인사이트", "zh-Hans": "AI 洞察"},
        "AI is analyzing your trip data to provide personalized insights": {"fr": "L'IA analyse vos données de voyage pour des insights personnalisés", "es": "La IA está analizando tu viaje para ofrecer insights personalizados", "de": "KI analysiert Ihre Reisedaten für personalisierte Einblicke", "it": "L'IA sta analizzando il viaggio per insights personalizzati", "pt": "A IA está a analisar a sua viagem para insights personalizados", "ja": "AIが旅行データを分析してパーソナライズされた分析を提供", "ko": "AI가 여행 데이터를 분석하여 맞춤 인사이트를 제공합니다", "zh-Hans": "AI 正在分析您的旅行数据以提供个性化洞察"},
        "Analyzing your trip...": {"fr": "Analyse de votre voyage…", "es": "Analizando tu viaje…", "de": "Ihre Reise wird analysiert…", "it": "Analisi del viaggio…", "pt": "A analisar a sua viagem…", "ja": "旅行を分析中…", "ko": "여행 분석 중…", "zh-Hans": "正在分析您的旅行…"},
        "Budget Health": {"fr": "Santé du budget", "es": "Salud del presupuesto", "de": "Budget-Gesundheit", "it": "Salute del budget", "pt": "Saúde do orçamento", "ja": "予算の健全性", "ko": "예산 상태", "zh-Hans": "预算状况"},
        "Trip Duration": {"fr": "Durée du voyage", "es": "Duración del viaje", "de": "Reisedauer", "it": "Durata del viaggio", "pt": "Duração da viagem", "ja": "旅行期間", "ko": "여행 기간", "zh-Hans": "旅行时长"},
        "Weather Check": {"fr": "Météo", "es": "Previsión", "de": "Wetter", "it": "Meteo", "pt": "Previsão", "ja": "天気", "ko": "날씨", "zh-Hans": "天气"},
        "Smart analysis for: \\(trip.name)": {"fr": "Analyse pour : \\(trip.name)", "es": "Análisis para: \\(trip.name)", "de": "Analyse für: \\(trip.name)", "it": "Analisi per: \\(trip.name)", "pt": "Análise para: \\(trip.name)", "ja": "分析対象: \\(trip.name)", "ko": "분석 대상: \\(trip.name)", "zh-Hans": "智能分析：\\(trip.name)"},
        "No Insights Yet": {"fr": "Pas encore d'insights", "es": "Sin insights aún", "de": "Noch keine Insights", "it": "Nessun insight ancora", "pt": "Sem insights ainda", "ja": "まだインサイトはありません", "ko": "아직 인사이트 없음", "zh-Hans": "暂无洞察"},
        "Adventure Activities": {"fr": "Activités aventure", "es": "Actividades de aventura", "de": "Abenteuer-Aktivitäten", "it": "Attività avventura", "pt": "Atividades de aventura", "ja": "アドベンチャーアクティビティ", "ko": "어드벤처 활동", "zh-Hans": "探险活动"},
        "Budget Optimization": {"fr": "Optimisation du budget", "es": "Optimización del presupuesto", "de": "Budget-Optimierung", "it": "Ottimizzazione budget", "pt": "Otimização do orçamento", "ja": "予算最適化", "ko": "예산 최적화", "zh-Hans": "预算优化"},
        "Central Park & Museums": {"fr": "Central Park et musées", "es": "Central Park y museos", "de": "Central Park & Museen", "it": "Central Park e musei", "pt": "Central Park e museus", "ja": "セントラルパークと博物館", "ko": "센트럴 파크 및 박물관", "zh-Hans": "中央公园与博物馆"},
        "Cultural Experiences": {"fr": "Expériences culturelles", "es": "Experiencias culturales", "de": "Kulturelle Erlebnisse", "it": "Esperienze culturali", "pt": "Experiências culturais", "ja": "文化体験", "ko": "문화 체험", "zh-Hans": "文化体验"},
        "Eiffel Tower Visit": {"fr": "Visite de la tour Eiffel", "es": "Visita a la torre Eiffel", "de": "Eiffelturm-Besuch", "it": "Visita alla torre Eiffel", "pt": "Visita à torre Eiffel", "ja": "エッフェル塔見学", "ko": "에펠탑 방문", "zh-Hans": "埃菲尔铁塔参观"},
        "Extended Stay Tips": {"fr": "Conseils long séjour", "es": "Consejos para estancias largas", "de": "Tipps für längere Aufenthalte", "it": "Consigli per soggiorni lunghi", "pt": "Dicas para estadias longas", "ja": "長期滞在のヒント", "ko": "장기 체류 팁", "zh-Hans": "长住提示"},
        "Local Exploration": {"fr": "Exploration locale", "es": "Exploración local", "de": "Lokale Erkundung", "it": "Esplorazione locale", "pt": "Exploração local", "ja": "地元探索", "ko": "현지 탐험", "zh-Hans": "当地探索"},
        "Shibuya & Harajuku": {"fr": "Shibuya et Harajuku", "es": "Shibuya y Harajuku", "de": "Shibuya & Harajuku", "it": "Shibuya e Harajuku", "pt": "Shibuya e Harajuku", "ja": "渋谷と原宿", "ko": "시부야 & 하라주쿠", "zh-Hans": "涩谷与原宿"},
        "Short Trip Tips": {"fr": "Conseils court séjour", "es": "Consejos para viajes cortos", "de": "Tipps für Kurztrips", "it": "Consigli per viaggi brevi", "pt": "Dicas para viagens curtas", "ja": "短期旅行のヒント", "ko": "짧은 여행 팁", "zh-Hans": "短途旅行提示"},
        "Activities": {"fr": "Activités", "es": "Actividades", "de": "Aktivitäten", "it": "Attività", "pt": "Atividades", "ja": "アクティビティ", "ko": "활동", "zh-Hans": "活动"},
        "destinations": {"fr": "destinations", "es": "destinos", "de": "Reiseziele", "it": "destinazioni", "pt": "destinos", "ja": "目的地", "ko": "목적지", "zh-Hans": "目的地"},
        "Transportation": {"fr": "Transport", "es": "Transporte", "de": "Transport", "it": "Trasporto", "pt": "Transporte", "ja": "交通", "ko": "교통", "zh-Hans": "交通"},
        "Travelers": {"fr": "Voyageurs", "es": "Viajeros", "de": "Reisende", "it": "Viaggiatori", "pt": "Viajantes", "ja": "旅行者", "ko": "여행자", "zh-Hans": "旅行者"},
    }

def load_fr_phrase_map_json():
    """Load optional JSON with more French phrase -> { es, de, it, pt, ja, ko, zh-Hans }."""
    if os.path.isfile(PHRASE_MAP_JSON):
        with open(PHRASE_MAP_JSON, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}

# Optional: English phrase -> { fr, es, de, it, pt, ja, ko, zh-Hans } for keys still in English in FR file
EN_PHRASE_MAP_JSON = os.path.join(TRANSLATIONS_DIR, "en_phrase_map.json")

def load_en_phrase_map_json():
    """Load optional JSON: English phrase -> { fr, es, de, it, pt, ja, ko, zh-Hans }."""
    if os.path.isfile(EN_PHRASE_MAP_JSON):
        with open(EN_PHRASE_MAP_JSON, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}

def build_en_to_langs(en_entries, fr_dict, fr_to_langs):
    """Build English phrase -> { fr, es, de, it, pt, ja, ko, zh-Hans } from existing FR map."""
    en_to_langs = {}
    for key, en_val in en_entries:
        fr_val = fr_dict.get(key, "")
        if fr_val and fr_val in fr_to_langs:
            trans = fr_to_langs[fr_val]
            en_to_langs[en_val] = {"fr": fr_val, **trans}
    return en_to_langs

def main():
    en_entries = parse(EN_FILE)
    fr_dict = dict(parse(FR_FILE))
    fr_to_langs = load_fr_to_langs()
    extra = load_fr_phrase_map_json()
    for k, v in extra.items():
        if isinstance(v, dict) and k not in fr_to_langs:
            fr_to_langs[k] = v
    en_to_langs = build_en_to_langs(en_entries, fr_dict, fr_to_langs)
    for k, v in load_en_phrase_map_builtin().items():
        en_to_langs[k] = {**en_to_langs.get(k, {}), **v}
    en_extra = load_en_phrase_map_json()
    for k, v in en_extra.items():
        if isinstance(v, dict):
            en_to_langs[k] = {**en_to_langs.get(k, {}), **v}
    all_langs = ["fr", "es", "de", "it", "pt", "ja", "ko", "zh-Hans"]
    for lang in all_langs:
        out_path = os.path.join(BASE, f"Localizable_{lang}.strings")
        lines = [f"/* Localizable_{lang}.strings - {lang} */", ""]
        for key, en_val in en_entries:
            fr_val = fr_dict.get(key, "")
            trans = fr_to_langs.get(fr_val) or en_to_langs.get(en_val)
            if lang == "fr":
                val = fr_dict.get(key) or (trans.get("fr") if trans else None) or en_val
            else:
                val = (trans.get(lang) if trans else None) or en_val
            val_esc = escape_string(val)
            lines.append(f'"{key}" = "{val_esc}";')
        with open(out_path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        print(f"Wrote {out_path} ({len(en_entries)} keys)")

if __name__ == "__main__":
    main()
