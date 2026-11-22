# Amic Invisible

Aplicació web per organitzar sortejos d'amic invisible, pensada per funcionar **sense servidor propi**: una pàgina estàtica a GitHub Pages i una base de dades a Supabase (plans gratuïts).

Qualsevol persona pot crear un compte i organitzar els seus esdeveniments. Un administrador general pot veure'ls tots.

## Què fa

- **Organitzadors**: es registren amb correu i contrasenya, i gestionen només els seus esdeveniments (nom, data, pressupost).
- **Participants**: nom i correu (obligatori) i, opcionalment, pistes de regal.
- **Sorteig amb control total**: restriccions (*no pot regalar a*, *ha de regalar a*), opció d'evitar regals recíprocs, sorteig aleatori i possibilitat de corregir qualsevol assignació a mà.
- **Enllaços secrets**: cada participant rep un enllaç únic (amb codi de 4 xifres opcional) i només veu el seu amic invisible.
- **Missatge amb camps automàtics**: `{nom}`, `{esdeveniment}`, `{data}`, `{pressupost}`, `{enllaç}` i `{codi}`, amb un text d'exemple.
- **Enviament per correu**: el correu s'obre ja redactat a Gmail (web) o a l'aplicació de correu, i l'envia l'organitzador des del seu compte. També hi ha botó de WhatsApp.
- **Panell d'administració general**: total d'usuaris, esdeveniments, participants, sortejos i enllaços; permet obrir i eliminar qualsevol esdeveniment.

## Com funciona

```
Navegador ── index.html (GitHub Pages) ──► Supabase
                                            ├─ Auth (comptes)
                                            ├─ Postgres: events, links, admins (amb RLS)
                                            └─ Funcions: get_link, is_admin, admin_overview
```

- El sorteig es fa al navegador de l'organitzador i es desa a la taula `events`.
- En publicar els enllaços, es desa a `links` només el que cada participant pot veure.
- Els participants no tenen accés a les taules: només poden cridar `get_link(token, codi)`.
- Cada organitzador només accedeix als seus esdeveniments (*Row Level Security*); els administradors, a tots.
- La llibreria `supabase-js` es carrega per CDN (versió fixada).

## Instal·lació pas a pas

### 1. Còpia del projecte
Fes un *fork* d'aquest repositori o crea'n un de nou (públic) i puja-hi els fitxers.

### 2. Projecte a Supabase
1. Crea un projecte gratuït a [supabase.com](https://supabase.com).
2. A les opcions de *Data access* en crear-lo: **Enable Data API** activat, **Grant API access to new tables automatically** desactivat, **Enable RLS on new tables automatically** activat.
3. A l'*SQL Editor*, enganxa i executa tot el contingut de `supabase.sql`. Es pot tornar a executar sense errors.
4. A *Authentication → Sign In / Providers*, activa **Allow new users to sign up** i decideix si vols exigir confirmació del correu (*Confirm email*).

### 3. Configuració
1. Copia `config.example.js` com a `config.js`.
2. Omple la URL del projecte i la clau **publishable** (a *Connect*, o a *Project Settings → Data API* i *API Keys*).
3. Mai hi posis la clau secreta (`sb_secret_…` o `service_role`).

### 4. Publicació
A GitHub: *Settings → Pages → Deploy from a branch → main / (root)*. L'adreça serà `https://elteu-usuari.github.io/nom-del-repositori/`.

### 5. Fer-te administrador general
Registra't a l'aplicació i, a l'*SQL Editor*, executa una sola vegada:

```sql
insert into admins(user_id) select id from auth.users where email = 'EL_TEU_CORREU' on conflict do nothing;
```

Recarrega l'aplicació: apareixerà el botó **Administració**.

## Seguretat i privadesa

- La clau *publishable* és pública per disseny. La protecció real són les polítiques RLS i els permisos de `supabase.sql`.
- Les contrasenyes les gestiona Supabase Auth i no són accessibles des de l'aplicació.
- Els noms i correus dels participants són **dades personals**. Si obres l'aplicació a persones que no coneixes, informa-les de qui hi té accés (l'administrador general veu tots els sortejos) i tingues en compte la normativa de protecció de dades (RGPD).
- El correu integrat de Supabase té límits molt baixos, pensats per a proves. Per a un ús real, configura el teu propi servei de correu o desactiva la confirmació.
- Comprova els límits actuals del pla gratuït de Supabase. Els projectes gratuïts es poden pausar per inactivitat, i es reactiven des del tauler (*Resume project*).

## Limitacions

- No envia correus automàticament: n'obre un de redactat per cada persona. Fer-ho automàtic requeriria una funció de Supabase i un servei d'enviament amb domini propi.
- La comprovació del correu valida només el format, no que l'adreça existeixi.
- No s'ha provat amb grups molt grans.

## Fitxers

| Fitxer | Contingut |
|---|---|
| `index.html` | Tota l'aplicació (HTML, CSS i JavaScript) |
| `config.js` | URL i clau pública del teu projecte de Supabase |
| `config.example.js` | Plantilla de configuració |
| `supabase.sql` | Taules, seguretat i funcions de la base de dades |
| `LICENSE` | Llicència MIT |

## Llicència

[MIT](LICENSE). Pots usar-lo, copiar-lo i modificar-lo lliurement.
