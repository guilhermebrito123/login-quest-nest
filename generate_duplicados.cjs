const XLSX = require("xlsx");

const data = [
  { ID: "7a6d37d1-24e7-4d7e-be2f-c9d53aaf11ed", Nome: "Camila barbara franca de jesus", CPF: "09077957650", Email: "", Telefone: "", Cidade: "", Status: "ativo", Criado_em: "2026-01-30 18:55:50" },
  { ID: "c6a0fff4-b3d9-41b6-8dca-d787f8a2d0ef", Nome: "Camila Barbara França de Jesus", CPF: "09077957650", Email: "", Telefone: "", Cidade: "", Status: "ativo", Criado_em: "2026-02-05 14:39:00" },
  { ID: "c50e010d-0f72-45e2-b9ae-34ab963e3868", Nome: "José Antônio  da  Silva", CPF: "68686790410", Email: "", Telefone: "", Cidade: "", Status: "ativo", Criado_em: "2026-02-04 16:12:40" },
  { ID: "0a404d5f-37a1-4eec-94fe-7559046af80d", Nome: "José Antônio da Silva", CPF: "68686790410", Email: "", Telefone: "", Cidade: "", Status: "ativo", Criado_em: "2026-01-22 15:08:33" },
  { ID: "f3ed6359-5866-4dae-a6e1-bfc5cedf17ae", Nome: "Rosimary Soares dos Reis", CPF: "97045292600", Email: "", Telefone: "3182668192", Cidade: "", Status: "ativo", Criado_em: "2026-03-04 13:05:20" },
  { ID: "92600f80-fc04-44ea-92b6-f47d6d39c981", Nome: "Rosimary Soares dos Reis", CPF: "97045292600", Email: "", Telefone: "", Cidade: "", Status: "ativo", Criado_em: "2026-03-04 14:35:16" },
];

const ws = XLSX.utils.json_to_sheet(data);
ws["!cols"] = [
  { wch: 38 }, { wch: 35 }, { wch: 14 }, { wch: 20 }, { wch: 15 }, { wch: 15 }, { wch: 10 }, { wch: 22 },
];
const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, ws, "CPFs Duplicados");
XLSX.writeFile(wb, "public/diaristas_cpf_duplicados.xlsx");
console.log("Done");
