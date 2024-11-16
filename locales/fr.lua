local Translations = {

    lang_s1 = 'Ouvrir la Boutique du Ranch',
    lang_s2 = 'Menu du Propriétaire de la Boutique du Ranch',
    lang_s3 = 'Voir les Articles de la Boutique',
    lang_s4 = 'voir les articles de la boutique du ranch',
    lang_s5 = 'Réapprovisionner la Boutique du Ranch',
    lang_s6 = 'réapprovisionner votre stock',
    lang_s7 = 'Consulter l\'Argent du Ranch',
    lang_s8 = 'vérifier et retirer l\'argent de la boutique du ranch',
    lang_s9 = 'Menu Client de la Boutique du Ranch',
    lang_s10 = 'Boutique du Ranch',
    lang_s11 = 'voir les articles en vente',
    lang_s12 = 'Prix unitaire : $',
    lang_s13 = 'Menu de la Boutique',
    lang_s14 = 'Stock du Ranch',
    lang_s15 = 'Combien ?',
    lang_s16 = 'vous devez avoir cette quantité dans votre inventaire',
    lang_s17 = 'Prix de Vente',
    lang_s18 = 'exemple : 0.10',
    lang_s19 = 'Une erreur est survenue, vérifiez que vous avez le montant et le prix corrects !',
    lang_s20 = 'Montant invalide',
    lang_s21 = 'Solde : $',
    lang_s22 = 'Retirer de l\'argent',
    lang_s23 = 'L\'argent vous sera donné en espèces !',
    lang_s24 = 'Retrait maximum : $',
    lang_s25 = '(sensible à la casse)',
    lang_s26 = 'ajouté à la boutique du ranch',
    lang_s27 = 'ajouté à la boutique du ranch',
    lang_s28 = 'Vous manquez d\'argent',
    lang_s29 = 'Aucun Article',
    lang_s30 = 'aucun article en stock à ajouter',
    lang_s31 = 'réapprovisionnement du stock',

    error = {
        no_wagon_setup = 'aucune charrette configurée',
        already_have_wagon = 'vous avez déjà une charrette de société',
        not_the_boss = 'vous n\'êtes pas le patron',
    },
    success = {
        wagon_stored = 'charrette de société rangée',
        wagon_setup_successfully = 'charrette de société configurée avec succès',
    },
    primary = {
        wagon_out = 'charrette de société sortie',
        wagon_already_out = 'votre charrette de société est déjà sortie',
    },
    menu = {
        wagon_menu = 'Menu de la Charrette',
        wagon_setup = 'Configurer la Charrette (Patron)',
        wagon_get = 'Obtenir la Charrette',
        wagon_store = 'Ranger la Charrette',
        close_menu = '>> Fermer le Menu <<',
    },

}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
