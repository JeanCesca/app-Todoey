//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var itemArray: [Item] = []
    
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    //context = intermediário entre o PersistentContainer (que armazena TODOS os dados)
    //preciso do 'context' para salvar, atualizar, ler os dados ou apagá-los
    //Create, Read, Uptade e Destroy = CRUD
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    //DATA STORAGE:
    //FILEMANAGER: PARA DADOS CUSTOMIZADOS.
    //USER DEFAULT: PARA DADOS MAIS SIMPLES.
    //CORE DATA: ?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }
    
//MARK: - DATASOURCE METHODS
    //As duas funções iniciais de TableView para gerar e alimentar as células.
    
    //Método para dizer a quantidade de CELLS, em relação ao tamanho da Array.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    //Método que mostra o LAYOUT (como será apresentada) a CELL.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoItemCell", for: indexPath)
        let cellItem = itemArray[indexPath.row]
        
        cell.textLabel?.text = cellItem.title
        
        //Determina o que o TRUE e o FALSE vão fazer (adicionar ou não a checkmark)
        cell.accessoryType = cellItem.done ? .checkmark : .none
        
        return cell
    }
    
//MARK: - TABLEVIEW DELEGATE METHODS
    
    //Método ativado quando CLICO nas CELLS.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //CRUD - Esse é o DESTROY:
//        context.delete(itemArray[indexPath.row])
//        itemArray.remove(at: indexPath.row)
        
        //CRUD - Esse é o UPDATE: Eu clico em uma row, e ela mostra ou não o sinal de "done"
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        
        saveItems()
        
        //Seleciona apenas uma vez e some o background
        tableView.deselectRow(at: indexPath, animated: true)
        
    }

//MARK: - GERA A JANELA DE UIAlert E ADICIONA NOVAS CELLS (+)
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        //1. Criar uma janela de alerta
        let createUIAlert = UIAlertController(title: "Adicionar novo item", message: "", preferredStyle: .alert)
        
        //2. Ação
        let createActionButton = UIAlertAction(title: "Adicionar", style: .default) { action in
            //o que irá acontecer quando o usuário clica no botão 'Adicionar novo item no UIAlert
            
            //CRUD ----
            //Core Data: crio um novo objeto do tipo Item
            //Atribuo a cada propriedade, um valor e salvo ela
            let newItem = Item(context: self.context)
            newItem.title = textField.text!
            newItem.done = false
            newItem.parentCategory = self.selectedCategory
            
            self.itemArray.append(newItem)
            
            self.saveItems()
            
        }
        
        //Criar o Placeholder dentro do UIAlert
        createUIAlert.addTextField { alertTextField in
            alertTextField.placeholder = "Crie um novo item"
            textField = alertTextField
        }
        
        //3. Adicionar a 'action' ao botao de alerta
        createUIAlert.addAction(createActionButton)
        
        //4. Mostrar o alerta
        present(createUIAlert, animated: true, completion: nil)
    }
    

    //CRUD - Esse é o CREATE - Ele armazena os dados no Database (só armazena, não mostra na tela ainda)
    func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
            
        self.tableView.reloadData()
    }
    
    //CRUD - Esse é o READ - Ele puxa os dados (fetch) armazenados no DataBase para a tela do APP.
    
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
        
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [additionalPredicate, categoryPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        
        do {
            //Aqui diz: tente puxar os dados do CONTEXT por fetch, e adicionar a Array de items.
            itemArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        
        tableView.reloadData()
    }
}

//MARK: - Search Bar Methods (Delegate)
extension TodoListViewController: UISearchBarDelegate {
    
    //PUXAR OS DADOS DO DATABASE
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //Criar uma requisição de fetch (FetchRequest) a uma Entity:
        let request: NSFetchRequest<Item>
        request = Item.fetchRequest()
        
        //QUERY: modo de filtrar o que iremos procurar.
        
        //Adicionar um 'predicate', ou seja, o modo que será puxada o dado.
        //Igualando o predicate que eu criei para a propriedade do fetchRequest
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        
        //O modo que eu irei procurar o dado: Nesse caso, em ordem alfabética (ascending)
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
     
        loadItems(with: request, predicate: predicate)
    }
    
    //
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()

            }
        }
    }
}

