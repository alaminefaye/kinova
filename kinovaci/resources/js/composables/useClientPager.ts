import { computed, ref, watch, type Ref } from 'vue'

/** Pagination côté navigateur pour les petites listes chargées en une fois. */
export function useClientPager<T>(items: Ref<T[]>, perPage = 10) {
  const page = ref(1)
  const lastPage = computed(() => Math.max(1, Math.ceil(items.value.length / perPage)))
  const pageItems = computed(() => items.value.slice((page.value - 1) * perPage, page.value * perPage))

  watch(lastPage, (last) => {
    if (page.value > last) page.value = last
  })

  return { page, lastPage, pageItems, perPage }
}
